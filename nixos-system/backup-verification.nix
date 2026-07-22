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
# *restorable* into a working service.  This module fills that gap by
# rotating through declared services, restoring one per night from the
# local repo into an isolated environment, and exercising the service to
# prove the backup is usable end-to-end.  Test outcomes emit prometheus
# metrics through the same textfile collector as backup success, so the
# same alerting infrastructure catches verification failures.
#
# Design
# ------
# Two probe styles cover the fleet:
#
#   probeType = "nixosVm"
#     Boots a full NixOS VM (via pkgs.nixosTest), bind-mounts the
#     extracted data in at /mnt/restore, and runs a testScript that
#     restores the data into service dirs / DB, starts the service, and
#     hits a health endpoint.  Used for anything that benefits from
#     "does the actual app come up and respond?" — native NixOS services
#     and OCI containers alike.  QEMU is ~30-60s of overhead per test;
#     invisible at homelab scale.
#
#   probeType = "shell"
#     Runs an arbitrary shell snippet against the extracted data.  Used
#     for services where booting the app adds no signal — hardware-bound
#     (zwavejs USB dongle, zigbee2mqtt coordinator), or file-only checks
#     (parse JSON, verify device IDs, sha256 sample files against a
#     manifest).
#
# Rotation
# --------
# A single timer fires nightly and runs the "next" probe using a
# round-robin index file, so 20 services means each is verified roughly
# every 20 days.  Simpler than assigning each probe a fixed weekday and
# scales evenly as probes are added or removed.
#
# Where it does and does not fit
# ------------------------------
# * Off-site DR (proving the B2 copy is recoverable) is a separate
#   concern; not implemented here.  Planned as a monthly nixosTest that
#   pulls from B2 first, or an aspen-orchestrated test that pulls
#   juniper's local repo over Tailscale SSH — that variant also proves
#   recoverability on foreign hardware, which is stronger than
#   traditional 3-2-1 verification.
# * Full-archive readability (does every chunk decode) is already
#   covered by tier-0 `borg check --verify-data` weekly; this module
#   doesn't duplicate it.
# * Canary-manifest fidelity checks (file-level "was the backup faithful
#   to source-at-quiesce time") were considered and dropped for
#   simplicity.  Reintroduce as a "shell" probe later if needed.
#
# `recoveryPlan` on service modules (consumed by nixServiceRecoveryScript
# in backups.nix) and `backups.verification.probes` overlap on paths
# and DB metadata but stay separate for now.  A future refactor could
# unify them into one `service.backupSpec` option.
#
# Not wired into any host — services must opt in by declaring probes.
##############################################################################

let
  cfg = config.backups.verification;
  hostName = config.networking.hostName;
  repoPath = "${config.backups.borgDir}/${hostName}";
  borgPasswdFile = "/run/secrets/borgCryptPasswd";

  # prometheus node_exporter textfile collector reads *.prom from here;
  # backups.nix already writes borgbackup_last_success_timestamp_seconds here
  metricsDir = "/var/lib/prometheus/node-exporter-text-files";

  # stable path bind-mounted into every VM under test at /mnt/restore
  # (populated by the runtime script before invoking the test driver)
  currentRestoreDir = "${cfg.scratchDir}/current";

  rotationIndexFile = "${cfg.scratchDir}/rotation-index";

  probeList = lib.attrValues cfg.probes;
  probeNames = map (p: p.serviceName) probeList;

  # borg archives paths without the leading slash; extract commands need
  # the same shape ("/var/lib/foo" → "var/lib/foo")
  borgPath = p: lib.removePrefix "/" p;

  # atomic prom textfile write — tmp+rename so scrapes never see a partial
  emitMetric = { name, labels, value }: ''
    {
      echo "# HELP ${name} unix timestamp of last successful ${name}"
      echo "# TYPE ${name} gauge"
      echo '${name}{${labels}} '${value}
    } > "${metricsDir}/${name}.prom.$$"
    mv "${metricsDir}/${name}.prom.$$" "${metricsDir}/${name}.prom"
  '';

  # ─── nixosTest derivation builder ───────────────────────────────────────
  #
  # Wraps the probe's user-supplied vmConfig with the shared-dir plumbing
  # that lets us inject restored data at runtime.  The `source` path is a
  # plain string (not a nix path), so nix doesn't try to verify it exists
  # at eval time; the runtime script ensures the symlink is in place
  # before invoking the driver.
  #
  # Invocation at runtime: ${test.driver}/bin/nixos-test-driver
  # Runs outside the nix sandbox, so real host paths work for shared dirs.

  mkVmTest = probe: pkgs.nixosTest {
    name = "verify-backup-${probe.serviceName}";
    nodes.machine = args: lib.recursiveUpdate (probe.vmConfig args) {
      virtualisation = {
        memorySize = probe.vmMemory;
        cores = probe.vmCores;
        # 9p bind-mount host scratch dir into the VM
        sharedDirectories.restore = {
          source = currentRestoreDir;
          target = "/mnt/restore";
        };
      };
    };
    testScript = probe.testScript;
  };

  # ─── per-probe verification script ─────────────────────────────────────

  mkVmVerifyScript = probe: let
    test = mkVmTest probe;
  in pkgs.writeShellScriptBin "verifyBackup-${probe.serviceName}" ''
    #!/bin/bash
    set -euo pipefail

    if [ "$(id -u)" -ne 0 ]; then
      echo "ERROR: This script must be run as root"
      exit 1
    fi

    export BORG_PASSPHRASE=$(cat ${borgPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    scratch=$(mktemp -d -p ${cfg.scratchDir} verify-${probe.serviceName}.XXXXXX)
    cleanup() { rm -rf "$scratch" "${currentRestoreDir}"; }
    trap cleanup EXIT INT TERM

    echo "=========================================="
    echo "Verifying backup: ${probe.serviceName} (nixosVm)"
    echo "=========================================="

    latest=$(${pkgs.borgbackup}/bin/borg list --short --last 1 ${repoPath})
    echo "Archive under test: $latest"

    echo ""
    echo "Extracting service data to scratch..."
    cd "$scratch"
    ${pkgs.borgbackup}/bin/borg extract ${repoPath}::"$latest" \
      ${lib.concatStringsSep " " (map (p: lib.escapeShellArg (borgPath p)) probe.extractItems)}

    # publish the current extraction at the stable path the VM expects
    ln -sfn "$scratch" "${currentRestoreDir}"

    echo ""
    echo "Booting test VM and running assertions..."
    # nixos-test-driver runs QEMU, executes the testScript, exits 0 on pass
    ${test.driver}/bin/nixos-test-driver

    echo ""
    echo "=========================================="
    echo "✓ ${probe.serviceName} verified"
    echo "=========================================="

    ${emitMetric {
      name = "backup_service_restore_test_last_success_timestamp_seconds";
      labels = "host=\"${hostName}\",service=\"${probe.serviceName}\",probe_type=\"nixosVm\"";
      value = "\"$(date +%s)\"";
    }}
  '';

  mkShellVerifyScript = probe: pkgs.writeShellScriptBin "verifyBackup-${probe.serviceName}" ''
    #!/bin/bash
    set -euo pipefail

    if [ "$(id -u)" -ne 0 ]; then
      echo "ERROR: This script must be run as root"
      exit 1
    fi

    export BORG_PASSPHRASE=$(cat ${borgPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    scratch=$(mktemp -d -p ${cfg.scratchDir} verify-${probe.serviceName}.XXXXXX)
    trap 'rm -rf "$scratch"' EXIT INT TERM

    echo "=========================================="
    echo "Verifying backup: ${probe.serviceName} (shell)"
    echo "=========================================="

    latest=$(${pkgs.borgbackup}/bin/borg list --short --last 1 ${repoPath})
    echo "Archive under test: $latest"

    echo ""
    echo "Extracting service data to scratch..."
    cd "$scratch"
    ${pkgs.borgbackup}/bin/borg extract ${repoPath}::"$latest" \
      ${lib.concatStringsSep " " (map (p: lib.escapeShellArg (borgPath p)) probe.extractItems)}

    echo ""
    echo "Running shell assertions..."
    export EXTRACT_DIR="$scratch"
    ${probe.script}

    echo ""
    echo "=========================================="
    echo "✓ ${probe.serviceName} verified"
    echo "=========================================="

    ${emitMetric {
      name = "backup_service_restore_test_last_success_timestamp_seconds";
      labels = "host=\"${hostName}\",service=\"${probe.serviceName}\",probe_type=\"shell\"";
      value = "\"$(date +%s)\"";
    }}
  '';

  mkVerifyScript = probe:
    if probe.probeType == "nixosVm" then mkVmVerifyScript probe
    else mkShellVerifyScript probe;

  # ─── rotation driver ───────────────────────────────────────────────────
  #
  # Fired by a single nightly timer.  Reads an index from disk, computes
  # `next = probes[index % len(probes)]`, starts that probe's oneshot
  # service, and increments the index.  With N probes, each is exercised
  # every N nights.

  rotationScript = pkgs.writeShellScriptBin "verifyBackupNext" ''
    #!/bin/bash
    set -euo pipefail

    if [ "$(id -u)" -ne 0 ]; then
      echo "ERROR: This script must be run as root"
      exit 1
    fi

    probes=(${lib.escapeShellArgs probeNames})
    if [ ''${#probes[@]} -eq 0 ]; then
      echo "No probes declared, nothing to verify"
      exit 0
    fi

    idx=$(cat ${rotationIndexFile} 2>/dev/null || echo 0)
    probe="''${probes[$((idx % ''${#probes[@]}))]}"
    echo $((idx + 1)) > ${rotationIndexFile}

    echo "Rotation index $idx of ''${#probes[@]}, running: $probe"
    systemctl start "verifyBackup-$probe.service"
  '';

in {

  ##############################################################################
  # option surface
  ##############################################################################

  options.backups.verification = {

    enable = lib.mkEnableOption "automated per-service backup restore verification";

    scratchDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/backup-verify";
      description = ''
        Scratch dir for extract/verify workflows.  Sized for the largest
        single service's data + dump (a few GB is usually plenty).  A
        dedicated dataset with a quota is recommended on hosts with a
        ZFS/BTRFS bulk pool.
      '';
    };

    startTime = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 04:00:00";
      description = ''
        When to run the nightly rotation.  Default 04:00 sits well after
        the 02:20–02:35 backup window with headroom for slow backups.
      '';
    };

    probes = lib.mkOption {
      default = {};
      description = ''
        Per-service verification probes.  Declared from service modules,
        e.g. `backups.verification.probes.vaultwarden = { ... }` inside
        vaultwarden.nix.  Empty by default — module is inert until at
        least one service opts in.
      '';
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {

          serviceName = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "identifier used in metric labels and script names";
          };

          probeType = lib.mkOption {
            type = lib.types.enum [ "nixosVm" "shell" ];
            description = ''
              `nixosVm` boots a NixOS VM with the service enabled,
              bind-mounts extracted data at /mnt/restore, and runs a
              testScript that restores + asserts.  `shell` runs an
              arbitrary snippet against the extracted data with
              $EXTRACT_DIR set to the scratch root.
            '';
          };

          extractItems = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = ''
              Absolute paths in the archive to extract.  Typically the
              service's data dir and its .sql.gz dump.  Mirrors the
              `restoreItems` field on the corresponding recoveryPlan.
            '';
            example = [ "/var/lib/vaultwarden" "/var/backup/postgresql/vaultwarden.sql.gz" ];
          };

          # ─── nixosVm options ──

          vmConfig = lib.mkOption {
            type = lib.types.nullOr (lib.types.functionTo lib.types.attrs);
            default = null;
            description = ''
              NixOS module (function form: `{ config, pkgs, lib, ... }: {...}`)
              describing the test VM.  Typically imports the production
              service module and overrides bits unsuitable for the test
              env (external URLs, mail creds, OIDC endpoints, etc).
              Required when probeType = "nixosVm".
            '';
            example = lib.literalExpression ''
              { config, pkgs, lib, ... }: {
                imports = [ ./vaultwarden.nix ];
                services.vaultwarden.environmentFile = pkgs.writeText "test-env" '''
                  DOMAIN=http://localhost:8222
                  DATABASE_URL=postgresql://vaultwarden@/vaultwarden
                  SIGNUPS_ALLOWED=false
                ''';
              }
            '';
          };

          testScript = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = ''
              nixosTest driver script (Python) run against the booted VM.
              Extracted data lives at /mnt/restore inside the VM.
              Required when probeType = "nixosVm".

              Typical shape:
                machine.wait_for_unit("postgresql.service")
                machine.succeed("systemctl stop <svc>.service || true")
                machine.succeed("sudo -u postgres dropdb --if-exists <svc>")
                machine.succeed("sudo -u postgres createdb -O <svc> <svc>")
                machine.succeed("gunzip -c /mnt/restore/var/backup/postgresql/<svc>.sql.gz "
                                "| sudo -u postgres psql <svc>")
                machine.succeed("rm -rf /var/lib/<svc>/*")
                machine.succeed("cp -a /mnt/restore/var/lib/<svc>/. /var/lib/<svc>/")
                machine.succeed("chown -R <svc>:<svc> /var/lib/<svc>")
                machine.systemctl("start <svc>.service")
                machine.wait_for_unit("<svc>.service")
                machine.wait_for_open_port(<port>)
                machine.succeed("curl -sf http://localhost:<port>/alive")
            '';
          };

          vmMemory = lib.mkOption {
            type = lib.types.int;
            default = 1024;
            description = "VM memory in MB (only relevant for nixosVm)";
          };

          vmCores = lib.mkOption {
            type = lib.types.int;
            default = 2;
            description = "VM CPU cores (only relevant for nixosVm)";
          };

          # ─── shell options ──

          script = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = ''
              Shell snippet run against the extracted data.
              $EXTRACT_DIR points at the scratch root; extracted paths
              live under $EXTRACT_DIR/<original-absolute-path>.
              Non-zero exit → verification fails.
              Required when probeType = "shell".
            '';
            example = ''
              # verify zwavejs device configs parse as JSON
              for f in "$EXTRACT_DIR/var/lib/docker/volumes/zwavejs/_data/config"/*.json; do
                jq empty "$f" || { echo "FAIL: bad json in $f"; exit 1; }
              done
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

    # basic sanity: nixosVm probes need vmConfig+testScript, shell probes need script
    assertions = lib.flatten (map (probe: [
      {
        assertion = probe.probeType != "nixosVm" || (probe.vmConfig != null && probe.testScript != null);
        message = "probe ${probe.serviceName}: probeType=nixosVm requires both vmConfig and testScript";
      }
      {
        assertion = probe.probeType != "shell" || probe.script != null;
        message = "probe ${probe.serviceName}: probeType=shell requires script";
      }
    ]) probeList);

    systemd.tmpfiles.rules = [
      "d ${cfg.scratchDir} 0700 root root -"
    ];

    # user-facing binaries for on-demand spot checks:
    #   sudo verifyBackupNext            → run whichever probe is next in rotation
    #   sudo verifyBackup-<service>      → run a specific probe now
    environment.systemPackages =
      [ rotationScript ] ++ map mkVerifyScript probeList;

    systemd.services =
      lib.mapAttrs' (n: probe: lib.nameValuePair "verifyBackup-${probe.serviceName}" {
        description = "backup restore verification: ${probe.serviceName}";
        wantedBy = lib.mkForce [];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${mkVerifyScript probe}/bin/verifyBackup-${probe.serviceName}";
          # keep the systemd invocation window long enough for slow VM boots
          TimeoutStartSec = "30min";
        };
        # reuse the existing failure notification path so verify failures
        # page the same way backup failures do
        unitConfig.OnFailure = "backupFailureEmail.service backupFailureWebhook.service";
      }) cfg.probes
      // {
        "verifyBackupNext" = {
          description = "advance rotation and start next backup verification";
          wantedBy = lib.mkForce [];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${rotationScript}/bin/verifyBackupNext";
          };
        };
      };

    systemd.timers.verifyBackupNext = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.startTime;
        Persistent = true;
      };
    };

    # ─── monitoring integration (to add to monitoring-server.nix separately) ──
    #
    # When wiring this module into hosts, add this alert to the
    # backup_alerts group in monitoring-server.nix, mirroring the existing
    # backupStale / backupMetricAbsent pattern.  Staleness threshold should
    # be `probe_count_per_host * 1 day + slack`; e.g. for 15 probes on a
    # host, alert if any single probe hasn't passed in >20 days.
    #
    #   - alert: backupServiceRestoreTestStale
    #     expr: time() - backup_service_restore_test_last_success_timestamp_seconds > 1728000  # 20d
    #     for: 1h
    #     labels: { severity: warning }
    #     annotations:
    #       summary: "restore test for {{ $labels.service }} on {{ $labels.host }} hasn't passed in >20d"

  };
}
