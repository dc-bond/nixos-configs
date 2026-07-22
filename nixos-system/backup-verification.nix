{ pkgs, config, lib, configVars, ... }:

##############################################################################
# BACKUP VERIFICATION MODULE
#
# Purpose
# -------
# The existing backup pipeline (see backups.nix) proves that the borg
# repository is intact and reachable — via nightly `borg check`, weekly
# `--verify-data`, and the borgbackup_last_success_timestamp_seconds
# dead-man's-switch metric consumed by prometheus.
#
# What it does NOT prove is that the archive contents are actually
# *restorable* into a working service.  This module adds automated,
# non-destructive verification tiers that exercise the full restore path
# on a schedule, isolated from production data, and emit their own
# prometheus metrics so the same alerting infrastructure catches
# verification failures the same way it catches backup failures.
#
# Tier layout
# -----------
#   T0 — Continuous (already in backups.nix)
#        `borg check` nightly, `--verify-data` Sundays, freshness metric.
#
#   T1 — Restorability smoke test (this module; nightly, per host)
#        Extracts the DB dumps and canary-manifest data from the latest
#        archive into a scratch dir, verifies dumps are non-empty and
#        gzip-valid, and diffs regenerated file hashes against the
#        archived manifest.  A full-archive `borg extract --dry-run`
#        proves every chunk is readable without touching disk.
#
#   T2 — Service-level semantic verification (this module; weekly, rotating)
#        For each declared probe, extracts that service's data, spins up
#        an ephemeral postgres cluster on a private socket, restores the
#        dump into it, and runs per-service SQL assertions ("known canary
#        user exists", "row counts non-zero", etc).  Proves the data is
#        semantically usable, not just structurally intact.
#
#   T3 — Off-site DR drill (planned, separate file)
#        Monthly nixosTest that pulls a copy from Backblaze B2, boots a
#        throwaway VM with the target service module, restores into it,
#        and hits the HTTP endpoint.  Proves the 3-2-1 off-site copy is
#        actually recoverable.  Not implemented here.
#
# Canary manifest ("sibling dir" approach)
# ----------------------------------------
# For a "was this backup faithful to the source?" check that doesn't race
# with live writes, each probe declares a stable subset of files whose
# sha256s are captured at backup time.  The manifest is written to a
# separate directory (manifestDir below) which is added to the borg
# archive.  During T1 verification, hashes are regenerated against the
# extracted files and diffed against the archived manifest.  Divergence
# means the backup captured a corrupted or inconsistent view of source.
#
# Kept out of the service data dir so backups don't mutate application
# state during the preHook.
#
# Design decisions worth remembering
# ----------------------------------
# * Probes live on the service module (`backups.verification.probes.<name>
#   = { ... }`), not centralized here — same pattern as the existing
#   `services.borgbackup.jobs.<host>.paths = lib.mkAfter [...]` calls.
#   Adding verification to a service is one attr block; deleting the
#   service removes the probe automatically.
# * `recoveryPlan` (defined per-service, consumed by nixServiceRecoveryScript)
#   and `backups.verification.probes` overlap on paths/DB metadata but are
#   kept separate for now.  A future refactor could unify them into a
#   single `service.backupSpec` module option that both the recover and
#   verify pipelines consume.
# * Tier 1 does a full-repo `borg extract --dry-run` (reads every chunk,
#   writes nothing) plus a targeted real extract of just DB dumps + manifest
#   data.  This is important for hosts like aspen that back up multi-TB
#   media paths — we must not naively full-extract those nightly.
# * Postgres refuses to run as root, so the ephemeral cluster in T2 runs
#   as `nobody` via `runuser`; the borg passphrase file and repo are read
#   as root (systemd unit is root) and dump contents are piped into the
#   unprivileged psql via stdin.
#
# Not wired into any host — services must opt in by adding probes.
##############################################################################

let
  cfg = config.backups.verification;
  hostName = config.networking.hostName;
  repoPath = "${config.backups.borgDir}/${hostName}";
  borgPasswdFile = "/run/secrets/borgCryptPasswd";

  # prometheus node_exporter textfile collector reads *.prom from here;
  # tier-0 (backups.nix) already writes borgbackup_last_success_timestamp_seconds here
  metricsDir = "/var/lib/prometheus/node-exporter-text-files";

  # sibling dir for canary manifests — this dir is added to the borg archive
  # so manifests round-trip alongside the data they describe
  manifestDir = "/var/lib/backup-manifests";

  probeList = lib.attrValues cfg.probes;

  # borg archives paths without the leading slash, so extract commands need
  # the same shape ("/var/lib/foo" → "var/lib/foo")
  borgPath = p: lib.removePrefix "/" p;

  # Atomic prom textfile write.  Filename must be stable so scrapes see the
  # latest value under the same series; tmp+rename avoids partial reads.
  emitMetric = { name, labels, value }: ''
    {
      echo "# HELP ${name} unix timestamp of last successful ${name}"
      echo "# TYPE ${name} gauge"
      echo '${name}{${labels}} '${value}
    } > "${metricsDir}/${name}.prom.$$"
    mv "${metricsDir}/${name}.prom.$$" "${metricsDir}/${name}.prom"
  '';

  # ─── T1: nightly restorability smoke test ───────────────────────────────
  #
  # Runs three checks:
  #   1. `borg extract --dry-run` on the full archive — proves every chunk
  #      is readable end-to-end without writing any data to disk.  This is
  #      stronger than `borg check` because it forces the same code path a
  #      real restore would use.
  #   2. Targeted extract of DB dumps + manifest data + manifest-referenced
  #      files → verifies dumps are non-empty and gzip-valid.
  #   3. Regenerates sha256s over extracted manifest files and diffs against
  #      the archived manifest → proves backup fidelity to source state.

  # paths to extract for real (small enough to always be safe)
  tier1ExtractPaths =
    lib.optional (probeList != []) (borgPath manifestDir)
    ++ (map (p: borgPath p.dbDump) (lib.filter (p: p.dbDump != null) probeList))
    ++ lib.flatten (map (p: map borgPath p.manifestPaths) probeList);

  tier1Script = pkgs.writeShellScriptBin "verifyBackupSmoke" ''
    #!/bin/bash
    set -euo pipefail

    if [ "$(id -u)" -ne 0 ]; then
      echo "ERROR: This script must be run as root"
      exit 1
    fi

    export BORG_PASSPHRASE=$(cat ${borgPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    scratch=$(mktemp -d -p ${cfg.scratchDir} smoke.XXXXXX)
    trap 'rm -rf "$scratch"' EXIT INT TERM

    echo "=========================================="
    echo "Tier 1 smoke test — ${hostName}"
    echo "=========================================="

    latest=$(${pkgs.borgbackup}/bin/borg list --short --last 1 ${repoPath})
    echo "Archive under test: $latest"

    # (1) full-archive readability — reads every chunk, writes nothing
    echo ""
    echo "Verifying full-archive readability (dry-run extract)..."
    ${pkgs.borgbackup}/bin/borg extract --dry-run ${repoPath}::"$latest"

    ${lib.optionalString (tier1ExtractPaths != []) ''
      # (2) targeted extract — pull only what we need to inspect
      echo ""
      echo "Extracting dumps + manifest data for inspection..."
      cd "$scratch"
      ${pkgs.borgbackup}/bin/borg extract ${repoPath}::"$latest" \
        ${lib.concatStringsSep " " (map lib.escapeShellArg tier1ExtractPaths)}
    ''}

    # per-probe checks
    ${lib.concatMapStringsSep "\n" (probe: ''
      echo ""
      echo "--- ${probe.serviceName} ---"

      ${lib.optionalString (probe.dbDump != null) ''
        dumpfile="$scratch${probe.dbDump}"
        if [ ! -s "$dumpfile" ]; then
          echo "FAIL: dump ${probe.dbDump} missing or empty"
          exit 1
        fi
        if ! ${pkgs.gzip}/bin/gunzip -t "$dumpfile" 2>/dev/null; then
          echo "FAIL: dump ${probe.dbDump} failed gzip integrity check"
          exit 1
        fi
        echo "OK: dump $(basename ${probe.dbDump}) present, non-empty, gzip-valid"
      ''}

      ${lib.optionalString (probe.manifestPaths != []) ''
        manifest="$scratch${manifestDir}/${probe.serviceName}.sha256"
        if [ ! -f "$manifest" ]; then
          echo "WARN: no canary manifest for ${probe.serviceName}"
          echo "  (backup preHook may not have run since probe was declared)"
        else
          # sha256sum -c reads relative paths from cwd; manifest was written
          # from / so entries are like "var/lib/foo/bar.pem"
          if ( cd "$scratch" && ${pkgs.coreutils}/bin/sha256sum -c "$manifest" --quiet ); then
            echo "OK: canary manifest matches extracted data"
          else
            echo "FAIL: canary manifest mismatch — backup captured inconsistent source state"
            exit 1
          fi
        fi
      ''}
    '') probeList}

    echo ""
    echo "=========================================="
    echo "✓ Smoke test passed"
    echo "=========================================="

    ${emitMetric {
      name = "backup_smoke_test_last_success_timestamp_seconds";
      labels = "host=\"${hostName}\"";
      value = "\"$(date +%s)\"";
    }}
  '';

  # ─── T2: per-service semantic verification ──────────────────────────────
  #
  # Extracts one service's data into an isolated scratch dir, spins up an
  # ephemeral postgres cluster on a unix socket (no TCP), restores the
  # dump into it, and runs per-service SQL assertions.  Postgres runs as
  # `nobody` via runuser because it refuses to run as root.  The dump is
  # piped into psql over stdin so we don't have to fix up file ownership.

  tier2Script = probe: pkgs.writeShellScriptBin "verifyBackup-${probe.serviceName}" ''
    #!/bin/bash
    set -euo pipefail

    if [ "$(id -u)" -ne 0 ]; then
      echo "ERROR: This script must be run as root"
      exit 1
    fi

    export BORG_PASSPHRASE=$(cat ${borgPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    scratch=$(mktemp -d -p ${cfg.scratchDir} verify-${probe.serviceName}.XXXXXX)
    pgdir="$scratch/pg"
    sockdir="$scratch/sock"

    cleanup() {
      # stop postgres if running; ignore errors during teardown
      if [ -f "$pgdir/postmaster.pid" ]; then
        ${pkgs.util-linux}/bin/runuser -u nobody -- \
          ${pkgs.postgresql}/bin/pg_ctl -D "$pgdir" -m immediate stop 2>/dev/null || true
      fi
      rm -rf "$scratch"
    }
    trap cleanup EXIT INT TERM

    echo "=========================================="
    echo "Tier 2 verification — ${probe.serviceName}"
    echo "=========================================="

    latest=$(${pkgs.borgbackup}/bin/borg list --short --last 1 ${repoPath})
    echo "Archive under test: $latest"

    # extract just this service's items
    echo ""
    echo "Extracting service data..."
    cd "$scratch"
    ${pkgs.borgbackup}/bin/borg extract ${repoPath}::"$latest" \
      ${lib.concatStringsSep " " (map (p: lib.escapeShellArg (borgPath p)) probe.extractItems)}

    ${lib.optionalString (probe.dbType == "postgresql") ''
      # ephemeral postgres cluster: unix-socket only, trust auth, no TCP
      # datadir is inside $scratch so teardown is one rm -rf
      echo ""
      echo "Starting ephemeral postgres cluster..."
      mkdir -p "$pgdir" "$sockdir"
      chown nobody:nogroup "$pgdir" "$sockdir"

      ${pkgs.util-linux}/bin/runuser -u nobody -- \
        ${pkgs.postgresql}/bin/initdb -D "$pgdir" -U verify --auth=trust \
        > "$scratch/initdb.log" 2>&1

      ${pkgs.util-linux}/bin/runuser -u nobody -- \
        ${pkgs.postgresql}/bin/pg_ctl -D "$pgdir" -l "$scratch/pg.log" \
        -o "-k $sockdir -h '' -c listen_addresses=''" \
        -w start

      export PGHOST="$sockdir"
      export PGUSER=verify

      ${pkgs.util-linux}/bin/runuser -u nobody --preserve-environment -- \
        ${pkgs.postgresql}/bin/createdb ${probe.dbName}

      echo "Restoring dump into ephemeral cluster..."
      # pipe as root, receive as nobody — avoids fixing dump file ownership
      ${pkgs.gzip}/bin/gunzip -c "$scratch${probe.dbDump}" \
        | ${pkgs.util-linux}/bin/runuser -u nobody --preserve-environment -- \
            ${pkgs.postgresql}/bin/psql -q ${probe.dbName}

      echo ""
      echo "Running semantic assertions..."
      # assertions run against the ephemeral cluster; PGHOST/PGUSER inherited
      ${lib.optionalString (probe.semanticSql != "") probe.semanticSql}
    ''}

    ${lib.optionalString (probe.semanticShell != "") ''
      echo ""
      echo "Running shell-level assertions..."
      export EXTRACT_DIR="$scratch"
      ${probe.semanticShell}
    ''}

    echo ""
    echo "=========================================="
    echo "✓ ${probe.serviceName} verified"
    echo "=========================================="

    ${emitMetric {
      name = "backup_service_restore_test_last_success_timestamp_seconds";
      labels = "host=\"${hostName}\",service=\"${probe.serviceName}\"";
      value = "\"$(date +%s)\"";
    }}
  '';

  # ─── canary manifest generator ─────────────────────────────────────────
  #
  # Runs inside each backup's preHook (after service quiesce, before borg
  # archives).  Writes sha256s of the probe's stable-subset files into a
  # sibling dir which is itself included in the archive, so the manifest
  # round-trips with the data it describes.
  #
  # Paths are hashed relative to /, so sha256sum -c during T1 can just
  # `cd $scratch && sha256sum -c manifest` and match extracted paths.

  manifestHook = probe:
    lib.optionalString (probe.manifestPaths != []) ''
      # capture stable-file hashes for ${probe.serviceName} canary manifest
      mkdir -p ${manifestDir}
      ( cd / && ${pkgs.coreutils}/bin/sha256sum \
          ${lib.concatStringsSep " " (map borgPath probe.manifestPaths)} \
          > ${manifestDir}/${probe.serviceName}.sha256 ) || exit 1
    '';

in {

  ##############################################################################
  # option surface
  ##############################################################################

  options.backups.verification = {

    enable = lib.mkEnableOption "automated backup recovery testing (T1 smoke + T2 semantic)";

    scratchDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/backup-verify";
      description = ''
        Isolated scratch dir for extract/verify workflows.  Should live on
        a filesystem with enough free space for the largest single service's
        data dir + dump (a few GB is usually plenty since bulk media paths
        are never fully extracted).  A dedicated dataset with a quota is
        recommended on hosts with a ZFS/BTRFS bulk pool.
      '';
    };

    tier1.startAt = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 04:00:00";
      description = ''
        When to run the nightly smoke test.  Default 04:00 sits after the
        02:20–02:35 backup window on aspen/juniper with headroom for a
        long backup to finish.
      '';
    };

    tier2.enable = lib.mkEnableOption "weekly per-service semantic verification (T2)";

    probes = lib.mkOption {
      default = {};
      description = ''
        Per-service verification probes.  Declared from service modules,
        e.g. `backups.verification.probes.vaultwarden = { ... }` inside
        vaultwarden.nix.  Empty by default — this module is inert until
        at least one service opts in.
      '';
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {

          serviceName = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "identifier used in metric labels and script names";
          };

          extractItems = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = ''
              Absolute paths in the archive to extract during T2.  Typically
              the service's data dir and its .sql.gz dump.  Mirrors the
              `restoreItems` field on the corresponding recoveryPlan.
            '';
            example = [ "/var/lib/vaultwarden" "/var/backup/postgresql/vaultwarden.sql.gz" ];
          };

          dbType = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum [ "postgresql" ]);
            default = null;
            description = ''
              Database engine for the ephemeral T2 cluster.  Only postgresql
              is implemented; mysql support can be added when a mysql-backed
              service needs it.  Leave null for file-only services.
            '';
          };

          dbName = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "database name inside the ephemeral cluster (typically matches service name)";
          };

          dbDump = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "absolute path (as stored in the archive) to the .sql.gz dump";
            example = "/var/backup/postgresql/vaultwarden.sql.gz";
          };

          manifestPaths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = ''
              Stable files (config, static assets, key material) whose sha256s
              are captured at backup time and verified after extract.  Exclude
              anything that changes on its own (logs, caches, thumbnails,
              session state).  Empty → skip manifest checks for this service.
            '';
            example = [ "/var/lib/vaultwarden/rsa_key.pem" ];
          };

          semanticSql = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = ''
              Shell snippet run against the ephemeral postgres cluster during
              T2.  PGHOST (socket dir) and PGUSER (verify) are pre-set.  Must
              exit 0 on pass, non-zero on fail.  Use psql -Atc for scalar
              queries.
            '';
            example = ''
              users=$(psql -Atc "SELECT count(*) FROM users")
              [ "$users" -gt 0 ] || { echo "FAIL: users table empty"; exit 1; }
            '';
          };

          semanticShell = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = ''
              Optional shell snippet for file-only assertions.  $EXTRACT_DIR
              points at the scratch root; the extracted service data lives
              under $EXTRACT_DIR/<original-absolute-path>.
            '';
          };

          rotationDay = lib.mkOption {
            type = lib.types.str;
            default = "Mon";
            description = ''
              systemd OnCalendar day-of-week for this probe's T2 run.
              Stagger across the week so one service is verified per night
              rather than piling all restores onto the same night.
            '';
          };
        };
      }));
    };
  };

  ##############################################################################
  # config
  ##############################################################################

  config = lib.mkIf cfg.enable {

    # scratch dir + manifest dir; both must exist before any hook runs
    systemd.tmpfiles.rules = [
      "d ${cfg.scratchDir} 0700 root root -"
      "d ${manifestDir}    0755 root root -"
    ];

    # user-facing binaries for on-demand spot checks:
    #   sudo verifyBackupSmoke
    #   sudo verifyBackup-<service>
    environment.systemPackages =
      [ tier1Script ] ++ map tier2Script probeList;

    systemd.services = {

      "verifyBackupSmoke" = {
        description = "tier-1 backup restorability smoke test";
        wantedBy = lib.mkForce [];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${tier1Script}/bin/verifyBackupSmoke";
        };
        # reuse the same alerting path the backup jobs already use
        unitConfig.OnFailure = "backupFailureEmail.service backupFailureWebhook.service";
      };

    } // lib.mapAttrs' (n: probe: lib.nameValuePair "verifyBackup-${probe.serviceName}" {
      description = "tier-2 restore verification: ${probe.serviceName}";
      wantedBy = lib.mkForce [];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${tier2Script probe}/bin/verifyBackup-${probe.serviceName}";
      };
      unitConfig.OnFailure = "backupFailureEmail.service backupFailureWebhook.service";
    }) cfg.probes;

    systemd.timers = {

      "verifyBackupSmoke" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.tier1.startAt;
          Persistent = true;
        };
      };

    } // lib.optionalAttrs cfg.tier2.enable (
      lib.mapAttrs' (n: probe: lib.nameValuePair "verifyBackup-${probe.serviceName}" {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "${probe.rotationDay} 05:00";
          Persistent = true;
        };
      }) cfg.probes
    );

    # capture the canary manifest during each backup, after service quiesce
    # (uses the existing backups.serviceHooks.preHook contract from backups.nix)
    backups.serviceHooks.preHook = lib.mkAfter (map manifestHook probeList);

    # include manifest dir in the archive so manifests round-trip with data
    services.borgbackup.jobs."${hostName}".paths = lib.mkAfter [ manifestDir ];

    # ─── monitoring integration (to add to monitoring-server.nix separately) ──
    #
    # When wiring this module into hosts, add these alerts to the
    # backup_alerts group in monitoring-server.nix (mirroring the existing
    # backupStale / backupMetricAbsent pattern):
    #
    #   - alert: backupSmokeTestStale
    #     expr: time() - backup_smoke_test_last_success_timestamp_seconds > 93600  # 26h
    #     for: 15m
    #     labels: { severity: critical }
    #     annotations:
    #       summary: "T1 backup smoke test on {{ $labels.host }} hasn't passed in >26h"
    #
    #   - alert: backupServiceRestoreTestStale
    #     expr: time() - backup_service_restore_test_last_success_timestamp_seconds > 691200  # 8d
    #     for: 30m
    #     labels: { severity: warning }
    #     annotations:
    #       summary: "T2 restore test for {{ $labels.service }} on {{ $labels.host }} hasn't passed in >8d"

  };
}
