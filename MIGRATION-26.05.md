# MIGRATION-26.05.md

Sequential runbook for moving the fleet from `nixos-25.11` to `nixos-26.05`.

**Target is 26.05, not 26.11.** 26.05 ("Xantusia" → the 26.05 release) is the
current stable as of 2026-09-25; 26.11 does not exist yet (branches in
November). Channel verified available: `nixos-26.05`, HEAD
`c508844df6c28fa6dabc1b6af70f3ccbd65c5201`.

Every eval-level finding below was verified by evaluating each host's
`system.build.toplevel.drvPath` against 26.05 with `home-manager` on
`release-26.05`. **All hosts evaluate cleanly once Phase 0 is done.**

**Scope:** cypress and alder are **deprecated** — offline, configs retained
against a possible future return, and explicitly *not* migrated. They still
evaluate cleanly against 26.05, so Phase 0's shared fixes keep them buildable
if they come back. In-scope hosts are **juniper, aspen, thinkpad, kauri**.

Reproduce that check any time without touching the tree:

```sh
nix eval --no-write-lock-file \
  --override-input nixpkgs github:nixos/nixpkgs/nixos-26.05 \
  --override-input home-manager github:nix-community/home-manager/release-26.05 \
  .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
```

---

## Phase 0 — shared fixes (no host switches yet)

Items 0.1-0.6 are hard eval errors or renames; 0.7 is a silent default change.
They land in shared modules,
so they must all be in place before *any* host switches. None of them changes
runtime behaviour on 25.11, so Phase 0 can be committed and switched on 25.11
first to confirm nothing regressed.

### 0.1 `services.promtail` is removed — migrate to Alloy

Promtail reached end of life and the module is gone in 26.05. This is the
single largest work item and it touches **every host**.

- `nixos-system/monitoring-client.nix:129` — aspen, thinkpad, cypress, kauri, alder
- `nixos-system/monitoring-server.nix:1266` — juniper (plus the
  `systemd.services.promtail` ordering block at `:1117`)

Migrate to `services.alloy` (`grafana-alloy` 1.16.0 in 26.05), not Fluent Bit:
Alloy keeps Loki's label model and journal semantics, so existing Grafana
dashboards and saved queries keep working. Fluent Bit would change label
shapes.

Both current scrape jobs have direct Alloy equivalents:

| promtail | alloy |
|---|---|
| `scrape_configs[].journal` | `loki.source.journal` |
| traefik `static_configs` + `__path__` | `local.file_match` + `loki.source.file` |
| `pipeline_stages[].json.expressions` | `loki.process` with `stage.json` |
| `clients[].url` | `loki.write` |

The module is a thin wrapper: config goes in
`environment.etc."alloy/config.alloy"` (Alloy syntax, not Nix attrs), and
`services.alloy.configPath` defaults to `/etc/alloy`. Writing it via
`environment.etc` rather than a store path is what enables config reload on
`nixos-rebuild switch`.

Carry over the two deliberate tunings from the promtail config, which exist for
good reasons and are documented inline today:

- bounded shutdown drain (`backoff_config.max_retries = 2`, `timeout = "2s"`)
  so an unreachable Loki can't hang the unit past `TimeoutStopSec` and fail a
  rebuild — Alloy equivalent is `loki.write`'s retry/backoff settings plus the
  unit's `TimeoutStopSec`
- the `after`/`wants = [ "loki.service" ]` ordering on juniper, so the shipper
  stops *before* Loki and can flush

**Cross-version note:** a host still on 25.11 running promtail can keep pushing
to juniper's 26.05 Loki 3.7 — the push API is unchanged. So juniper can go
first and the clients can migrate host by host.

### 0.2 `boot.initrd.preLVMCommands` — unsupported under systemd stage 1

26.05 makes systemd stage 1 the default (scripted initrd deprecated, removal in
26.11). `boot.initrd.preLVMCommands` then hard-fails an assertion.

- `nixos-system/boot.nix:50` — **shared by all hosts**

The body is only `setleds +num` (numlock LED). Simplest correct fix is to drop
it. If the numlock behaviour is wanted, re-add as a
`boot.initrd.systemd.services.<name>` unit instead.

This is also the point at which every host moves to systemd initrd, which is
the riskiest single change for the **LUKS workstations** (thinkpad, kauri,
alder — disko `type = "luks"`). systemd-cryptsetup replaces the scripted
password prompt. See Phase 3 for the mitigation.

### 0.3 Bind-mount `fsType` has no default anymore

`fileSystems.<name>.fsType` lost its default, so the `/etc/age` early bind
mount errors out on every impermanence host.

Add `fsType = "none";` alongside `options = [ "bind" ];` in:

- `hosts/aspen/impermanence.nix:22`
- `hosts/thinkpad/impermanence.nix:22`
- `hosts/cypress/impermanence.nix:22`
- `hosts/kauri/impermanence.nix:22`
- `hosts/alder/impermanence.nix:22`

(The `/` tmpfs entries already set `fsType`, so they are fine.)

### 0.4 `networking.resolvconf.enable` now conflicts with a managed `resolv.conf`

`networking.resolvconf.enable` defaults to `true` unconditionally in 26.05 and
asserts if `environment.etc."resolv.conf"` is also set — which it is on the
hosts that don't use systemd-resolved (juniper, aspen).

In `nixos-system/networking.nix`, gate it off on exactly those hosts:

```nix
networking.resolvconf.enable = lib.mkIf (!hostData.networking.useResolved) false;
```

### 0.5 `dhcpV6Config.RouteMetric` is no longer a valid networkd option

networkd 259 moved `RouteMetric` out of `[DHCPv6]`. Hard type error.

`nixos-system/networking.nix:72,80,91` — delete all three
`dhcpV6Config.RouteMetric` lines. They are dead config already: every one of
those networks sets `networkConfig.DHCP = "ipv4"`, so DHCPv6 never runs. The
`dhcpV4Config.RouteMetric` lines carry the actual interface priority and stay.

### 0.6 `services.resolved.llmnr` renamed

`nixos-system/networking.nix:19` — `llmnr = "false"` becomes
`settings.Resolve.LLMNR = "false"` (the module moved to RFC 42 settings).
Warning on 26.05, so not strictly blocking, but do it now.

### 0.7 `oci-containers` Restart default: `always` → `on-failure`

**No eval error, no warning — decide this deliberately.** 26.05 changes the
container unit template's `Restart=` from `always` to `on-failure`
(`nixos/modules/virtualisation/oci-containers.nix:539`, in the shared
backend-agnostic `serviceConfig`, so it applies to the docker backend).

Scope: **all 91 `docker-*` units on aspen** and the 4 on juniper are currently
`Restart=always` (verified at runtime).

What changes: a container that exits **cleanly** is no longer restarted. Under
`always` it was. That covers a graceful `docker stop`, a container that exits 0
on a transient condition, and recovery after a docker daemon restart.

This interacts with the repo's own container pattern — the
`docker-<app>-root.target` gating and the generated
`dockerServiceRecoveryScript` were written against `always` semantics.

Two defensible choices:

1. **Preserve current behaviour** (recommended for a migration — change one
   thing at a time). Set it back per-container or via the shared
   `oci-containers.nix` helper. Because the module sets `Restart` plainly rather
   than with `mkDefault`, restoring it needs `lib.mkForce`:

   ```nix
   systemd.services."docker-${app}".serviceConfig.Restart = lib.mkForce "always";
   ```

2. **Adopt the new default** and verify every container tolerates it. More
   correct long-term (a cleanly-exited one-shot container should stay stopped),
   but it is a behaviour change to validate across 95 units during an already
   large migration.

Either way, after switching, confirm every container returns after a reboot and
after a `systemctl restart docker`.

---

## Phase 1 — juniper (VPS: public DNS, monitoring server, matrix, vaultwarden)

Do juniper first. LAN DNS keeps working off aspen's pihole throughout, and
juniper's services are the smaller, better-isolated set.

### 1.1 Pre-switch config work

**Grafana `secret_key` is now mandatory** — `nixos-system/monitoring-server.nix`,
in the `${app2}` (grafana) `settings` block.

26.05 removed the built-in default. The old default was the publicly-known
literal `SW2YcwTIb9zpOOhoPsMm`. Anything already encrypted in `grafana.db` was
encrypted *with that key*, so **set it to the old value** rather than a fresh
one — a new key silently breaks decryption of existing stored secrets, and
upstream provides no rotation path (only a third-party tool).

Add it as a SOPS secret and reference it with Grafana's file provider so the
literal doesn't live in the public repo:

```nix
security.secret_key = "$__file{${config.sops.secrets.grafanaSecretKey.path}}";
```

Low blast radius either way: `grafana.db` is 1.7 MB, the two provisioned
datasources (Prometheus, Loki) carry no credentials, and the four installed
plugins are Grafana's own first-party React apps.

**Grafana 12.3.6 → 13.0.9.** Angular was already removed in 12, so that
migration is behind us. The removed Image Renderer plugin is not installed.

### 1.2 Back up what can't be rolled back

Postgres 17.10 → 17.11 is a patch bump (no dump/restore needed), but Synapse
migrates its own schema:

- `matrix-synapse` 1.155.0 → 1.161.0 — runs schema migrations on first start.
  **Not reversible by switching back a generation.**
- `vaultwarden` 1.36.0-via-unstable → 1.37.3 — see 1.3.

Nightly `postgresqlBackup` already covers `matrix-synapse` and `vaultwarden`.
Take a fresh dump immediately before switching and confirm it is non-empty,
rather than relying on the 02:20 run. Also copy `/var/lib/grafana/data/grafana.db`
aside.

### 1.3 Deviations to drop on juniper

| Deviation | Action |
|---|---|
| `vaultwarden` + `vaultwarden-webvault` unstable pin | **Drop.** 26.05 ships 1.37.3 / 2026.7.0+0 — identical to unstable, and ≥1.37.2 satisfies the recorded revert trigger |
| `matrix-synapse-attrs-fix` overlay | **Drop the whole overlay.** nixpkgs#530874 is fixed upstream (26.05's `matrix-synapse-unwrapped` has no `postPatch` at all) and synapse is past 1.155.0, so the `doCheck = false` trigger is met too. Removing it also restores binary-cache substitution, so synapse stops building locally on every rebuild |
| `crowdsec` / `crowdsec-firewall-bouncer` unstable pin | Optional drop → 26.05's 1.7.8 / 0.0.34 (25.11 had 1.7.2). Unstable is 1.8.1, a major bump — prefer 26.05 |
| `services.crowdsec` console-token auto-enrollment (commented out) | Re-test; the recorded trigger was "re-test after settling on a channel" |

### 1.4 Switch

Standard flow. Watch for: `alloy` coming up and Loki receiving, Synapse
migration completing, Grafana starting with the new `secret_key`, pihole +
unbound healthy, traefik certs intact, crowdsec bouncer attached.

---

## Phase 2 — aspen (homelab: 30+ services, ZFS, GPU, impermanence)

The big one. Two items here are genuinely dangerous and one of them produces
**no eval error at all**.

### 2.1 NVIDIA drops Pascal — fix this before switching

`nixos-system/nvidia.nix:17` sets
`package = config.boot.kernelPackages.nvidiaPackages.stable`.

- aspen's GPU is a **GTX 1060 6GB, compute capability 6.1 (Pascal)**
- it currently runs driver **580.142** (25.11's `stable`)
- 26.05's `stable` is **595.71.05**, which **no longer supports Pascal**

Nothing in the evaluation catches this. The result would be a GPU with no
working driver — and `nouveau` is blacklisted in the same module. That takes
out, at minimum:

- **Jellyfin** hardware transcoding (uses the GPU via nvidia-container-toolkit)
- **Frigate** detection/decoding (same)
- `ollama-cuda`, which is explicitly built for `cudaArches = [ "61" ]` (sm_61 = Pascal)
- `sunshine` streaming

Fix — 26.05 added `hardware.nvidia.branch` precisely for this, and the LTSB 580
branch is the documented home for Maxwell-through-Volta (GTX 9xx–10xx):

```nix
hardware.nvidia.branch = "legacy_580";   # and drop the explicit `package`
```

Verified: `linuxPackages_6_18.nvidiaPackages.legacy_580` = **580.173.02**,
builds against 26.05's default 6.18.53 kernel. Note `hardware.nvidia.package`
overrides `branch`, so the existing `package` line must go, not just sit
alongside.

### 2.2 ZFS + the kernel jump

- default kernel **6.12 → 6.18** (no host pins `boot.kernelPackages`)
- ZFS **2.3.7 → 2.4.4**; `pkgs.zfs.kernelModuleAttribute` is `zfs_2_4`, and
  `zfs_2_4` builds cleanly against 6.18.53

Pool safety: a ZFS userspace/kmod upgrade does **not** touch on-disk pool
features. The `storage` pool (10.9T, 2.66T allocated, ONLINE) stays readable by
2.3 as long as **`zpool upgrade` is never run**. Do not run it — that is the
one step here that is genuinely irreversible.

Optional de-risking, if you want to separate variables: pin
`boot.kernelPackages = pkgs.linuxPackages_6_12` on aspen for the channel bump
so only userspace moves, then take the kernel in a second switch.
`zfs_2_3` (2.3.9) is also still in 26.05 if you want to hold ZFS back too.

### 2.3 Non-rollbackable service migrations

**Home Assistant 2025.11.3 → 2026.5.4** (seven releases). Recorder is on
PostgreSQL (`recorder.db_url = "postgresql://@/hass"`), so the schema migration
lands in the `hass` database and a generation rollback will **not** undo it —
2025.11 cannot read the newer schema.

Well-bounded in practice: the `hass` DB is only **244 MB** with default 10-day
retention, so the migration is minutes, and `/persist` has 42 G free (HA wants
roughly the DB size in temp space). `postgresqlBackup` already covers `hass`
(~20 MB gzipped). Take a fresh dump right before switching.

I checked all seven releases' breaking changes against the actual config. The
scary-sounding ones do **not** apply:

| Upstream change | Applies here? |
|---|---|
| 2026.3 — light `color_temp`/mireds attributes removed | **No.** Active scenes in `home-assistant-scenes.nix` already use `color_temp_kelvin`. The mirek values only exist in `hue-backup/hue-scenes-reference.nix`, which is never imported |
| 2026.4 — MQTT `object_id` removed, replaced by `default_entity_id` | **Not blocking.** `object_id` appears only in a comment in `zigbee2mqtt.nix:37`. HA pins entity ids at first discovery, so existing entities are unaffected; only *future* renames/adoptions change. Update that comment's rename procedure and re-verify it the next time a fixture is renamed |
| 2026.5 — person/device_tracker "entered/left home" triggers and "is home" conditions removed | **No.** No presence triggers or `device_tracker`/`zone` conditions in the automations |
| 2026.5 — webhook `local_only` must be a real boolean | **No.** No HA webhooks configured |
| 2025.12 — `issues()` template returns only active issues | Not used |

Still to do for HA:

- `services.home-assistant.config.lovelace.mode = "yaml"`
  (`nixos-configs-private/nixos-system/home-assistant-lovelace.nix:1135`) now
  warns: HA 2026.8 renames it to `lovelace.dashboards` + `lovelace.resource_mode`.
  **Warning only on 26.05** — plan it, don't rush it into this migration.
- Re-verify the two custom frontend/integration pieces still build against
  2026.5: `energyPanelHide` (`buildHomeAssistantComponent`) and the pinned
  `card-mod` fetch.
- Re-test whether `doInstallCheck = false` on the HA override is still needed.

**Other state migrations on aspen:**

| Service | Change | Notes |
|---|---|---|
| Vikunja | 2.3.0 → 2.6.0 | DB migrations. The release note about "Vikunja v1.0.0 breaking changes / CORS" is **stale** for us — aspen already runs 2.3.0, so that transition is behind us. `frontendScheme`/`frontendHostname`/`environmentFiles` all still exist in 26.05. Dump `vikunja` first |
| Nextcloud | **stay on 32** | `nextcloud32` is still in 26.05 at 32.0.15. 26.05 only changes the *new-install* default to 33. **Deliberately decouple** the NC major upgrade from the channel bump — Nextcloud forbids skipping majors and `occ upgrade` is one-way. Do 32→33 as its own change afterwards (33/34/35 are all in 26.05) |
| Stirling-PDF | 1.5.0 → 2.14.3 (v1→v2) | Low risk here: settings migrate automatically and `stirling-pdf.nix` only sets `SERVER_PORT` and `INSTALL_BOOK_AND_ADVANCED_HTML_OPS` — none of the removed v1 keys (`appName`, `homeDescription`, `secureCookie`) or renamed JWT keys are used. Smoke-test the UI behind Authelia afterwards |
| Mosquitto | 2.0.22 → 2.1.2 | **No config change needed.** The 26.05 module internally switched to the upstream `mosquitto_acl_file.so` / `mosquitto_password_file.so` plugins while keeping the same `listeners[].users.<name>.{acl,passwordFile}` option surface. New assertion requires package ≥2.1 — satisfied. ACL files move from `/etc/mosquitto/` to `/var/lib/mosquitto/`, which impermanence already persists. Expect HA + zigbee2mqtt to reconnect |
| MariaDB | 10.11.14 → 10.11.18 | Patch bump. `photoprism` (167 MB) is the only real DB. `mysqlBackup` covers it |
| PostgreSQL | 17.10 → 17.11 | Patch bump, no dump/restore |

### 2.4 UniFi — do NOT drop the unstable pin

This one inverts the usual cleanup logic:

- aspen runs **10.6.101** from `pkgs.unstable`
- 26.05 ships **10.2.105**

Dropping the pin would be a **controller downgrade**, which UniFi does not
support — the config DB is migrated forward on upgrade and an older controller
won't read it. **Keep `pkgs.unstable.unifi`.** Update the `DEVIATIONS.md` row:
the original reason (25.11's 9.5.21 carried CVE-2026-22557/22558) no longer
applies, since 26.05's 10.2.105 has no `knownVulnerabilities` — but the
no-downgrade constraint replaces it as the reason to stay on unstable.

Do drop `services.unifi.jrePackage = pkgs.jdk25_headless`
(`nixos-system/unifi.nix:72`) — 26.05's module defaults `jrePackage` to
`jdk25_headless` on its own, so the override is now redundant.

Keep the `mongodb-ce` 8.0.32 pin as-is (the SSPL/no-binary-cache reasoning is
unchanged, and unifi 10.6's `<< 8.1.0` ceiling still applies).

### 2.5 Other aspen deviations

| Deviation | Action |
|---|---|
| `zigbee2mqtt` unstable pin | **Drop.** 26.05 ships 2.14.0, clearing the recorded "≥2.13.x" trigger |
| `sunshine` `pkgs-2505` pin | **Test to drop.** nixpkgs#475181 is still open, but 26.05's sunshine is 2026.516.143833 — far newer than the 25.11 build that regressed, and identical to unstable. If x11 capture works, drop the pin **and the entire `nixpkgs-2505` flake input**: sunshine is its only consumer, and 25.05 is long EOL, so today the fleet ships an unsupported channel for it |
| `lldap` `LoadCredential` workaround | Re-test. 26.05 substantially reworked the file-based settings (`ldap_user_pass_file`, `jwt_secret_file`, plus new assertions), so the `*_file` options may now work and the workaround can go |

### 2.5b Module default changes on aspen (no eval error — verified by source diff)

| Module | Change | Verdict |
|---|---|---|
| `services.calibre-web` | Now hardened: `ProtectSystem = "strict"`, `ProtectHome = true`, and `ReadWritePaths` computed as `dataDir` + `options.calibreLibrary` | **Safe.** `calibreLibrary` is set to `${bulkStorage.path}/media/library/ebooks/calibre/`, which resolves to a real directory on the ZFS `storage/root/media/library` dataset, so it lands in `ReadWritePaths`. Because `enableBookUploading = true` writes into that library, **smoke-test an upload** after switching |
| `services.lldap` | New `database.createLocally` (defaults **true**) and `database.type` (defaults **`"sqlite"`**); `settings.database_url` is now only a `mkDefault` | **Safe but tidy it up.** `lldap.nix` sets `database_url = "postgres:///lldap"` explicitly, which beats `mkDefault` — so there is *no* silent switch to an empty SQLite DB. But the defaults now misdescribe reality. Set `database.createLocally = false` to declare intent and keep the module from managing a DB it shouldn't. Ordering is already handled by the module's own `requires`/`after` on `postgresql.target` |
| `services.lldap` | `ldap_user_pass_file` / `jwt_secret_file` are now properly supported, with assertions | The `LoadCredential` + `LLDAP_*_FILE` workaround ("shit broken in 25.11") can likely be reverted to the native `*_file` options. Do it as a **separate** change after the switch, not during |
| `services.sunshine` | Module now sets `hardware.uinput.enable = true` instead of `boot.kernelModules = [ "uinput" ]` | `sunshine.nix:99` sets `boot.kernelModules = [ "uinput" ]` by hand — now redundant. Dropping it also picks up the udev rules and `uinput` group that `hardware.uinput.enable` brings |
| `services.zigbee2mqtt` | Config copy moved `preStart` → `ExecStartPre`; `RestartSec = 10` added | Functionally equivalent, no action |
| `services.vikunja` | New `address` option, default `""` → `interface = ":3456"` | Identical to the old hardcoded `":${port}"`, no action |
| `services.stirling-pdf` | `INSTALL_BOOK_AND_ADVANCED_HTML_OPS` now accepts a bool; module coerces bool *or* string | Their `"true"` string still works, no action |
| `services.photoprism` | `user`/`group` became options, defaults still `photoprism` | No action |
| `services.authelia` | `user`/`group`/`StateDirectory` now derived via `autheliaName` | For instance `dcbond` this yields `authelia-dcbond` — **identical** to the old hardcoded value, so state is not orphaned. No action |
| `services.redis` | New `group` option, default `config.user` | `user` still defaults to `redis-<name>`, so group is unchanged. No action |
| `services.home-assistant` | New `lovelaceConfig` / `lovelaceConfigFile` and `lovelace.dashboards`; new assertion if both `themes` and `config.frontend.themes` are set | All opt-in and null by default, so **no conflict** with the private module's `systemd.tmpfiles` `L+ /var/lib/hass/ui-lovelace.yaml`. Note these options are the sanctioned target for the deprecated `lovelace.mode` when that migration comes |
| `services.ollama` | `acceleration`, `listenAddress`, `sandbox`, `writablePaths` all removed | None are used — the config already uses the sanctioned `package = pkgs.ollama-cuda.override {...}`. No action |

**CUDA forward risk:** 26.05 ships CUDA **12.9** (25.11 had 12.8), which still
supports `sm_61`, and `ollama-cuda.override { cudaArches = [ "61" ]; }` still
evaluates. But CUDA 13 drops Pascal outright. That and the `legacy_580` driver
pin in 2.1 are the same clock running down — when 26.11 or 27.05 moves to CUDA
13, GPU compute on the GTX 1060 ends and the card needs replacing.

### 2.6 Switch

aspen is the build server for the workstations, so getting it onto 26.05 before
Phase 3 means the workstations build against an already-migrated builder.

Post-switch checks: GPU present (`nvidia-smi` shows 580.x), Jellyfin transcode
and Frigate detection both working, ZFS pool ONLINE and **not** upgraded, HA up
with recorder migrated and no missing entities, zigbee2mqtt paired with all 14
devices, mosquitto accepting both users, traefik routes green, all `docker-*`
units up.

---

## Phase 3 — workstations

Order: **thinkpad** (primary, and the host that invokes rebuilds) → **kauri**.
cypress and alder are deprecated and skipped.

### 3.1 The real risk is boot, not services

Phase 0.2 moves every host to systemd stage 1. thinkpad and kauri are both
**LUKS-encrypted via disko**, so the initrd password prompt changes from the
scripted implementation to systemd-cryptsetup. A failure here is a host that
won't boot, recoverable only at the physical machine.

With cypress retired there is no longer a non-LUKS impermanence workstation to
rehearse on — but **aspen already fills that role**: impermanence with a tmpfs
root and no LUKS. So by the time Phase 3 starts, systemd stage 1 has already
been proven twice: on juniper (plain btrfs, no LUKS, no impermanence) and on
aspen (impermanence + tmpfs root + ZFS). Only the cryptsetup variable is new.

Mitigations:

1. Use `nixos-rebuild boot` and reboot deliberately rather than `switch`, so you
   control when the new initrd is first exercised.
2. Keep the previous generation in the bootloader (`configurationLimit = 5`
   already does).
3. Do **kauri before thinkpad**. thinkpad is the host you drive rebuilds from,
   so it is the worst one to lose; kauri is the cheaper place to discover a
   systemd-cryptsetup problem. This inverts "primary first" deliberately.
4. Have the LUKS passphrase to hand and know the recovery path (boot previous
   generation from the bootloader menu) before rebooting.

### 3.2 Do not bump `home.stateVersion`

Every home-manager change surfaced by the evaluation is gated on
`home.stateVersion < 26.05` and stays on legacy behaviour while it is. Leaving
it alone defers all of these to a separate, deliberate change:

| Warning | Note |
|---|---|
| `programs.firefox.configPath` default → `$XDG_CONFIG_HOME/mozilla/firefox` | **The one with user data at stake** — adopting it means moving `~/.mozilla/firefox`, and native messaging hosts are not moved. Defer |
| `programs.vscode` → `programs.vscodium` | `programs.vscode` now always writes to VS Code's paths; the fork needs the `vscodium` module or config lands in the wrong place |
| `programs.ssh.matchBlocks` → `programs.ssh.settings` | `home-manager/chris/ssh.nix` |
| `swww` renamed to `awww` | Package rename |
| `wayland.windowManager.hyprland.configType` default `hyprlang` → `lua` | thinkpad + cypress |
| `gtk.gtk4.theme` default → `null` | |
| `programs.neovim.withRuby` / `withPython3` defaults → `false` | |
| `xfce.thunar-archive-plugin` / `thunar-volman` → top-level `pkgs.*` | |
| `xdg.userDirs.setSessionVariables` default change | |

### 3.3 Workstation deviations

| Deviation | Action |
|---|---|
| `librewolf` in `permittedInsecurePackages` (`librewolf-152.0.2-1`) | **Drop.** 26.05 ships 156.0-1 with no `knownVulnerabilities`, so the entry is stale |
| `mcp-nixos` unstable pin | **Drop.** 26.05 ships 2.4.3, clearing the "≥2.x" trigger (unstable is at 3.0.1 if you'd rather stay current) |
| `claude-code` unstable pin | **Keep** — ongoing CLI/extension parity preference, no revert trigger |
| `displaylink` 6.2 `requireFile` pin | **Keep.** Unchanged in 26.05; remember the hash is mirrored in `nixos-system/rebuilds.nix` and the prefetch must run on the *invoking* host |
| `pkgs-2105` / `openssl_1_0_2` (IWD:EE) | **Keep** — permanent by nature |

---

## Global cleanup (fold into whichever phase touches it)

- **`docker` overlay pin** (`overlays/default.nix:44`, `docker = prev.docker_29`)
  — **drop**. 26.05's default `docker` is already 29.8.0, so the pin is a no-op.
- **`simple-nixos-mailserver` flake input is dead.** Declared at
  `flake.nix:26` pinned to `nixos-25.11`, but no module from it is imported
  anywhere. Either remove the input or repoint it at `nixos-26.05` — left as-is
  it silently keeps a second nixpkgs tree in the lock.
- **`nixos-configs-private/CLAUDE.md` is stale**: it documents 3 exported
  modules, but the private flake exports **5** (`home-assistant-lovelace` and
  `home-assistant-scenes` are missing from the doc).
- **`DEVIATIONS.md` header and every row** need updating from "stock
  `nixos-25.11`" to 26.05, with the dropped rows deleted and the UniFi row's
  reason rewritten (see 2.4). Per repo convention that happens in the same
  commit as each code change.
- **Inputs to bump** alongside `nixpkgs`: `home-manager` →
  `release-26.05`. `sops-nix`, `disko`, `impermanence` and `firefox-addons`
  track rolling branches and will move on their own. `private` and `finplanner`
  are own repos — remember private edits need push + `nix flake update private`
  (or `--override-input private path:...`) before they are visible.
- **`services.mysql.package` pin is now load-bearing.** nixpkgs 26.05 moves the
  default MariaDB from 10.11 to **11.4**. `mysql.nix` pins `mariadb_1011`
  explicitly (10.11.18 in 26.05), so nothing moves — but that pin is now what
  prevents an unintended 10.11 → 11.4 jump on the `photoprism` database, rather
  than merely matching the default. Keep it, and note the 10.11 EOL is Feb 2028.
- **GCC 14 → 15** in 26.05. Only matters for things built from source here;
  dropping the `matrix-synapse` overlay (1.3) removes the largest such build.
- **glibc 2.42 no longer allows an executable stack** when a shared library
  requests one. Possible breakage for the Beamdog IWD:EE launcher
  (`home-manager/chris/icewind-dale.nix`), which runs under `steam-run` against
  `pkgs-2105.openssl_1_0_2`. Low stakes (a game), thinkpad-only now that cypress
  is retired — test it, don't gate the migration on it.
- **Stray file to remove on juniper**: `/var/lib/grafana/grafana.db`, a
  root-owned 0-byte file (the real DB is `/var/lib/grafana/data/grafana.db`).
  Harmless but misleading: `sudo rm /var/lib/grafana/grafana.db`.

---

## Verified non-issues

Checked against the configs and confirmed not to apply — recorded so they don't
get re-investigated:

- `services.jellyseerr` → `services.seerr` rename — jellyseerr runs as an OCI
  container (`oci-media-server.nix:273`), not the native module
- `mysql80` removal — the fleet uses `mariadb_1011`
- `nixos-rebuild` Bash→Python rewrite — every flag `rebuilds.nix` uses
  (`--flake`, `--target-host`, `--sudo`, `--ask-sudo-password`, `--option`,
  `list-generations`) exists in the 26.05 implementation
- Grafana 13 Angular removal — the four installed plugins
  (`exploretraces`, `lokiexplore`, `metricsdrilldown`, `pyroscope`) are
  Grafana's own React apps
- Nixpkgs-level removals that don't apply: `nodePackages`, `node2nix`,
  `yarn2nix`, `python3Full`, `substituteAll`, `neofetch`, `lunarvim`, the
  `pkgs.mate.*` / `pkgs.xfce.*` scopes (the thunar plugins surface only as
  home-manager warnings), PostgreSQL 13, Node.js 22→24, Ruby, GHC, Dovecot 2.4
- `requireFile` now treating `message`/`url` as literal strings — the
  displaylink overlay's message and URL contain no shell-expandable `$`
- home-manager: Firefox extensions moving to per-profile — `shared/firefox.nix`
  already uses `profiles.<name>.extensions.packages`
- home-manager: `programs.neovim.extraLuaConfig` → `initLua` — not used
- `services.openssh.enableRecommendedAlgorithms` (new, defaults true) — the
  curated Kex/MAC lists it applies are the same ones 25.11 already hardcoded, so
  effective SSH crypto is unchanged. If a client ever fails to negotiate, the
  escape hatch is `enableRecommendedAlgorithms = false`
- `services.logind` RFC 42 conversion — `thinkpad/configuration.nix` already
  uses the new `settings.Login.*` form
- Not configured anywhere in the fleet: `services.openssh.settings.AcceptEnv`,
  `services.openssh.banner`, `systemd.coredump.extraConfig`, `services.avahi`,
  `programs.light`, `services.esphome`, `services.oauth2-proxy`,
  `profiles/hardened`, `linux_hardened`, `linux-rt`, `security.acme`,
  `services.statsd`, `services.pyload`, `services.uptime`, `services.crabfit`,
  `services.stalwart-mail`, `services.portunus`, `services.tandoor-recipes`,
  `services.prometheus.exporters.rspamd`, `services.mattermost`,
  `services.immich`, `reiserfs`, `ecryptfs`, `rustic`, `wineWowPackages`

---

## Sequential checklist

The execution view of everything above. Each item links back to the phase
section that explains *why*.

### Phase 0 — shared fixes, no switching yet

Land all of these before *any* host switches. None changes 25.11 behaviour, so
this phase can be committed and switched on 25.11 first to confirm no
regression.

Phase 0 is executed in batches grouped by failure mode and test method, not by
item number. 6 of the 7 items land on 25.11; only 0.6 needs the bumped channel
(`services.resolved.settings` does not exist in 25.11).

| Batch | Items | Test | Status |
|---|---|---|---|
| 1 | 0.2, 0.4, 0.5, 0.7 | rebuild, inspect generated units | **done 2026-09-25** |
| 2 | 0.1 | logs arriving in Loki with label parity | pending |
| 3 | 0.3 | reboot, `/etc/age` + `/run/secrets` | pending |
| 4 | `boot.initrd.systemd.enable` on 25.11 | per-host reboot | pending |
| 5 | 0.6 + flake bump | full re-eval | pending |

Batch 4 is not a 26.05 requirement in itself — it takes systemd stage 1
voluntarily on 25.11, so the one change that can leave a host unbootable is
isolated from ~40 package upgrades. Verified to evaluate cleanly on 25.11 for
all four in-scope hosts.

- [ ] **0.1** Migrate `services.promtail` → `services.alloy`.
      `monitoring-client.nix:129` and `monitoring-server.nix:1266` (+ the
      ordering block at `:1117`). Biggest work item. Carry over the bounded
      shutdown drain and the `after`/`wants = [ "loki.service" ]` ordering.
      `services.alloy` exists in 25.11 with an identical option surface, so this
      lands and is verified before the channel bump.
- [x] **0.2** Deleted `boot.initrd.preLVMCommands` from `boot.nix` (and the now
      unused `pkgs` arg). Other modules still contribute to that option — the
      console keymap/font setup, and the disko LUKS unlock script on the
      laptops — which is consistent with the 26.05 assertion naming only
      `boot.nix`: those modules stop contributing under systemd stage 1.
- [ ] **0.3** Add `fsType = "none";` to the `/etc/age` bind mount in all five
      `hosts/*/impermanence.nix:22` — include cypress and alder so they stay
      buildable while deprecated. **Not** a no-op: 25.11 defaults `fsType` to
      `"auto"`, and this mount is `neededForBoot` and gates SOPS.
- [x] **0.4** Added `resolvconf.enable = lib.mkIf (!hostData.networking.useResolved) false`
      inside the existing `networking` block. No-op on 25.11 (already `false`
      fleet-wide); verified `false` on 26.05 for juniper and aspen, which is the
      point.
- [x] **0.5** Deleted the three `dhcpV6Config.RouteMetric` lines. Dead config —
      every one of those networks is `DHCP = "ipv4"`. Confirmed no `DHCPv6`
      section in any generated `.network` file, dhcpV4 metrics intact.
- [ ] **0.6** `networking.nix:19`: `llmnr = "false"` →
      `settings.Resolve.LLMNR = "false"`. Cannot be pre-landed —
      `services.resolved.settings` does not exist in 25.11, so this rides with
      the flake bump in Batch 5.
- [x] **0.7** Chose to preserve `always`, applied centrally in
      `oci-containers.nix` over `oci-containers.containers`. `mkForce` is
      required: the module sets `Restart` at normal priority, which already
      outranks the `mkOverride 500 "always"` in `oci-searxng.nix` and
      `oci-recipesage.nix` — so those lines have never taken effect and would
      have silently yielded `on-failure` on 26.05. Verified all 25 aspen and 4
      juniper container units `Restart=always` and active.
- [ ] Bump `flake.nix`: `nixpkgs` → `nixos-26.05`, `home-manager` →
      `release-26.05`. Either drop the dead `simple-nixos-mailserver` input or
      repoint it at `nixos-26.05`.
- [ ] Re-run the eval check on **all six** hosts (cypress and alder included) —
      expect clean.
- [ ] **Do not touch `home.stateVersion`.** It gates every home-manager change
      listed in §3.2, including the Firefox profile move.
- [ ] Add the `DEVIATIONS.md` row for the 0.7 `mkForce` — it only becomes a
      deviation at the channel bump, so it belongs in the Batch 5 commit.

#### Found during Batch 1, unrelated to 26.05

- [ ] `tailscale up --reset` in `tailscale.nix` restores `accept-dns` to its
      default of on, so tailscaled fights the declared
      `environment.etc."resolv.conf"` on both DNS servers. juniper lost the race
      during the Batch 1 rebuild: `/etc/resolv.conf` became a tailscale-written
      file holding only `100.100.100.100`, dropping the Quad9 fallbacks on the
      public DNS server. aspen carries the same latent conflict but was not
      clobbered. Fix: `--accept-dns=false` in `baseUpFlags`, gated on
      `!useResolved` so the resolved-based laptops are unaffected.

### Phase 1 — juniper

- [ ] Add `grafanaSecretKey` to SOPS set to the old default
      `SW2YcwTIb9zpOOhoPsMm`; wire as
      `security.secret_key = "$__file{...}"`. A *new* key breaks existing DB
      secrets and there is no upstream rotation path.
- [ ] Drop the `vaultwarden` + `vaultwarden-webvault` unstable pins (26.05 ships
      1.37.3 / 2026.7.0+0).
- [ ] Drop the whole `matrix-synapse-attrs-fix` overlay — fixed upstream; also
      restores cache substitution so synapse stops building locally on every
      rebuild.
- [ ] Optionally drop the `crowdsec` pins → 26.05's 1.7.8 (avoid unstable's
      1.8.x major).
- [ ] Fresh pre-switch dumps: `matrix-synapse`, `vaultwarden`; copy
      `/var/lib/grafana/data/grafana.db` aside. Verify non-empty.
- [ ] **Switch.**
- [ ] Verify: alloy shipping to Loki, Synapse schema migration finished, Grafana
      up on the new `secret_key`, pihole + unbound healthy, traefik certs
      intact, crowdsec bouncer attached.

### Phase 2 — aspen

- [ ] **Set `hardware.nvidia.branch = "legacy_580"` and remove the explicit
      `package` line** in `nvidia.nix:17`. Without this the GTX 1060 loses its
      driver entirely (595 dropped Pascal) and there is **no eval error**.
      `package` overrides `branch`, so the old line must go, not just sit
      alongside.
- [ ] Keep Nextcloud on `nextcloud32`. Do **not** fold the NC33 upgrade into
      this migration.
- [ ] **Keep** the `unifi` unstable pin — 26.05's 10.2.105 is a *downgrade* from
      the running 10.6.101 and UniFi does not support controller downgrades.
      Rewrite the `DEVIATIONS.md` reason (the CVE rationale is gone; the
      no-downgrade constraint replaces it).
- [ ] Drop `services.unifi.jrePackage` (`unifi.nix:72`) — the module now
      defaults to `jdk25_headless`.
- [ ] Drop the `zigbee2mqtt` unstable pin (26.05 ships 2.14.0).
- [ ] Set `services.lldap.database.createLocally = false`.
- [ ] Drop `boot.kernelModules = [ "uinput" ]` from `sunshine.nix:99`.
- [ ] Optional de-risk: pin `boot.kernelPackages = pkgs.linuxPackages_6_12` so
      only userspace moves, then take the 6.18 kernel as a second switch.
- [ ] Fresh pre-switch dumps: `hass` (244 MB, migration is minutes), `vikunja`,
      `nextcloud`, `lldap`, plus mysql `photoprism`.
- [ ] **Switch.**
- [ ] **Never run `zpool upgrade`** — the one genuinely irreversible step here.
      ZFS 2.3.7 → 2.4.4 leaves pool features alone otherwise.
- [ ] Verify: `nvidia-smi` reports 580.x; Jellyfin hardware transcode; Frigate
      detection; ZFS pool ONLINE and *not* upgraded; HA recorder migrated with
      no missing entities; zigbee2mqtt has all 14 devices; mosquitto accepts
      both users; **calibre-web book upload**; every container returns after a
      reboot and after `systemctl restart docker`.
- [ ] Afterwards, as separate changes: test dropping the `sunshine`
      `pkgs-2505` pin (if it works, drop the whole `nixpkgs-2505` input — 25.05
      is EOL); revert the lldap `LoadCredential` workaround to the native
      `*_file` options; re-test HA's `doInstallCheck = false`.

### Phase 3 — workstations

- [ ] **kauri before thinkpad.** Deliberately inverted from "primary first":
      thinkpad drives the rebuilds, so it is the worst host to lose to a
      systemd-cryptsetup problem. By this point systemd initrd is already proven
      on juniper (no LUKS, no impermanence) and aspen (impermanence + tmpfs
      root), so cryptsetup is the only new variable. **Operator decision.**
- [ ] Drop the stale `librewolf-152.0.2-1` `permittedInsecurePackages` entry
      (156.0-1 carries no `knownVulnerabilities`).
- [ ] Drop the `mcp-nixos` unstable pin (26.05 ships 2.4.3). Keep the
      `claude-code` pin — that is an ongoing parity preference, not a workaround.
- [ ] Use `nixos-rebuild boot` plus a deliberate reboot, not `switch`. LUKS
      passphrase to hand; the previous generation is in the bootloader menu.
- [ ] **kauri**: switch, reboot, confirm LUKS unlock.
- [ ] **thinkpad**: switch, reboot, confirm LUKS unlock.
- [ ] Test IWD:EE — may break on glibc 2.42's executable-stack refusal. Do not
      gate the migration on it.

### Closeout

- [ ] Drop the `docker` overlay pin — 26.05's default `docker` is already 29.8.0.
- [ ] Rewrite the `DEVIATIONS.md` header and rows for 26.05; delete dropped
      rows. Per repo convention, in the same commit as each code change.
- [ ] Update `nixos-configs-private/CLAUDE.md` — it documents 3 exported
      modules, the flake exports 5 (`home-assistant-lovelace` and
      `home-assistant-scenes` are missing).
- [ ] Update the entity-rename procedure comment at `zigbee2mqtt.nix:37` — HA
      2026.4 replaced MQTT `object_id` with `default_entity_id`. Existing entity
      ids are unaffected; only future renames and adoptions change.
- [ ] Plan HA `lovelace.mode` → `lovelace.dashboards` (warning only on 26.05;
      the new `lovelaceConfigFile` option is the clean target).
- [ ] Separately, later: Nextcloud 32 → 33 (then 34, 35 if wanted), one major
      version at a time.
