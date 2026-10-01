# DEVIATIONS.md

Central registry of everything in this flake that is **not** a stock
`nixos-26.05` build: cross-channel package pulls, version pins, overlays,
insecure-package allowances, config-level workarounds for upstream bugs, and
flake inputs that don't track a 26.05 release.

**Why this file exists:** these deviations are otherwise scattered across the
tree with only inline comments, and it's easy to forget one is in place long
after the upstream reason is gone. When you add, change, or remove any of the
items below, update this file in the same commit. Each entry carries a
**revert trigger** — the condition under which the deviation should be dropped.

Paths are relative to `nixos-configs/`. Line numbers drift; grep the symbol if
a link is stale.

---

## 1. Active cross-channel / pinned package versions

Packages deliberately taken from a channel other than `nixpkgs` (26.05), or
pinned to a specific non-channel version.

| File | Package | Source instead of 26.05 | Reason | Revert trigger |
|---|---|---|---|---|
| `nixos-system/sunshine.nix` | `sunshine` | `pkgs.pkgs-2505` (25.05) | 25.11 has an x11-capture crash regression ([nixpkgs#475181](https://github.com/NixOS/nixpkgs/issues/475181)) | Fix lands in 25.11 |
| `nixos-system/crowdsec.nix` | `crowdsec` | `pkgs.unstable` (1.8.1 vs 1.7.8 in 26.05) | **No-downgrade constraint.** juniper already runs 1.8.1 live; 26.05 ships 1.7.8, so dropping the pin would move the local crowdsec DB *backwards* across a major version. The original reason ("newer than the channel ships") no longer applies — this one replaces it | 26.05 backports ≥1.8.1, or crowdsec state is deliberately rebuilt on the older major |
| `nixos-system/crowdsec.nix` | `crowdsec-firewall-bouncer` | `pkgs.unstable` (0.0.36) | Kept in lockstep with `crowdsec` above | Same as `crowdsec` |
| `nixos-system/unifi.nix` | `unifi` | `pkgs.unstable` (10.6.101 vs 10.2.105 in 26.05) | **No-downgrade constraint.** The original CVE reason is gone — 26.05's 10.2.105 carries no `knownVulnerabilities` — but it is *older* than the running 10.6.101, and UniFi migrates its config DB forward on upgrade: an older controller will not read it. The `jrePackage` override is no longer needed; 26.05's module defaults to `jdk25_headless` on its own | 26.05 backports a `unifi` ≥ the running version |
| `nixos-system/unifi.nix` | `mongodb` | `mongodb-ce` pinned to 8.0.32, in place of the module default `pkgs.mongodb-7_0` | MongoDB is SSPL, so Hydra builds no MongoDB at all and nothing in nixpkgs has a binary substitute — `mongodb-7_0` compiles from source for 3-5h on aspen and wants ~15G at the `mongod` link, repeating on every bump. `mongodb-ce` is the same server from upstream's prebuilt tarball (`fetchurl` + `autoPatchelfHook`). Pinned rather than left at mongodb-ce's default because unifi 10.6.106's deb declares `mongodb-org-server (>= 3.6.0), (<< 8.1.0)` — 8.0 is the ceiling and the 8.2 mongodb-ce ships is above it | nixpkgs gains a cached or prebuilt mongodb inside unifi's declared range, or `services.unifi` grows a prebuilt option |
| `home-manager/chris/icewind-dale.nix` | `openssl_1_0_2` | `pkgs.pkgs-2105` (21.05) | Beamdog game binary links libssl 1.0.0, removed from nixpkgs after 21.05 | **Permanent** by nature (legacy ABI) |

### Parity pulls from unstable (intentional, not bug workarounds)

`claude-code` is pinned to unstable so the CLI and the VSCodium extension stay
on matching versions:

- `home-manager/chris/claude-code.nix` (thinkpad + cypress),
  `home-manager/danielle/claude-code.nix` (kauri) —
  `programs.claude-code.package = pkgs.unstable.claude-code` (CLI, declarative module)
- `home-manager/chris/vscodium.nix`, `home-manager/danielle/vscodium.nix` —
  `pkgs.unstable.vscode-extensions.anthropic.claude-code`

**Revert trigger:** none — this is an ongoing preference, kept until 26.05's
`claude-code` is current enough that parity no longer requires unstable.

`mcp-nixos` (the NixOS/Home Manager MCP server wired into `claude-code` in
`home-manager/chris/claude-code.nix` and `home-manager/danielle/claude-code.nix`)
is pulled from unstable. 26.05 ships 2.4.3; unstable is at 3.0.1.

**Revert trigger:** none while the channel lags. 26.05's 2.4.3 does clear the
original "≥ 2.x" trigger, but dropping the pin now would be a *major downgrade*
of a tool in daily use, for no gain. Same shape as the `unifi` and `crowdsec`
rows: the channel catching up does not help when you are already ahead of it.
Revisit if 26.05 reaches ≥ 3.x.

---

## 2. Global overlays

Repo-wide package modifications in `overlays/default.nix`, applied to every
host via `nixos-system/foundation.nix` (`nixpkgs.overlays`).

| Package | What it does | Revert trigger |
|---|---|---|
| `displaylink` | Pinned to **6.2** with a manual `requireFile` src + hash | Manual bump only; hash is mirrored in `nixos-system/rebuilds.nix` — keep the two in sync |

The overlay file also defines the cross-channel package sets consumed in §1:
`pkgs.unstable` (nixos-unstable), `pkgs.pkgs-2505` (25.05), `pkgs.pkgs-2105`
(21.05).

---

## 3. Config-level workarounds for upstream / 26.05 bugs

Not version pins, but deviations from a clean stock config, in place to work
around a specific bug. Each should be revisited when its linked issue closes.

| File | Workaround | Upstream reference / revert trigger |
|---|---|---|
| `nixos-system/lldap.nix` | Passwords/JWT passed via `systemd` `LoadCredential` instead of the module's file-based settings (`*_file` options commented out) | File-based settings broken in 25.11 — restore the `*_file` options when fixed |
| `nixos-system/crowdsec.nix` | Firewall-bouncer workaround — `preStart` touches `capi-credentials.yaml` / `lapi-credentials.yaml` before registration | [crowdsec#3632](https://github.com/crowdsecurity/crowdsec/issues/3632) |
| `nixos-system/crowdsec.nix` | **`crowdsec-firewall-bouncer-register.serviceConfig.StateDirectory` pinned back to `"crowdsec-firewall-bouncer-register"` (`mkForce`) and `ReadWritePaths = [ "/var/lib/crowdsec" ]` restored.** 26.05 added `crowdsec` to that unit's `StateDirectory` ([`crowdsec-firewall-bouncer.nix:260`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/services/security/crowdsec-firewall-bouncer.nix)). The unit runs `DynamicUser`, so systemd migrated `/var/lib/crowdsec` → `/var/lib/private/crowdsec` and left a symlink; `/var/lib/private` is `0700 root`, so `cscli` and anything else outside a service namespace could no longer traverse it (`mkdir /var/lib/crowdsec: file exists`). Needed a one-time on-disk repair as well — see MIGRATION-26.05.md | Upstream drops `crowdsec` from that unit's `StateDirectory`, or gives the register step a namespace-safe way to reach crowdsec's state. Re-test on the next channel bump |
| `nixos-system/crowdsec.nix` | **`environment.etc."crowdsec/config.yaml"`** mirrors the module's own `format.generate "crowdsec.yaml" cfg.settings.general`. 26.05's register script invokes the *unwrapped* `cscli` (`lib.getExe' cfg.package "cscli"`, `crowdsec-firewall-bouncer.nix:234`) instead of 25.11's `/run/current-system/sw/bin/cscli` wrapper, so it passes no `-c` and falls back to `/etc/crowdsec/config.yaml` — a path this config never populated, because the config lives in the store. Registration failed, no `api-key.cred` was written, and the bouncer died at `243/CREDENTIALS` with no `CROWDSEC_CHAIN` in iptables | Upstream restores the wrapped `cscli` (or passes `-c`) in the register script — then drop the `environment.etc` entry. **Fragile:** it duplicates one line of module internals, so re-check it whenever the crowdsec module changes |
| `nixos-system/crowdsec.nix` | Console-token auto-enrollment commented out | Possible upstream bug — re-test after settling on 25.11 |
| `nixos-system/yubikey.nix` | pcsclite polkit access-group workaround | [nixpkgs#121121](https://github.com/NixOS/nixpkgs/issues/121121) |
| `nixos-system/foundation.nix` | `nix.settings.nix-path = config.nix.nixPath` | [nix#9574](https://github.com/NixOS/nix/issues/9574) |
| `nixos-system/home-assistant.nix` | `doInstallCheck = false` on the HA package override | Drop when the install-check no longer fails |
| `nixos-system/home-assistant.nix` | `energy_panel_hide` custom integration (built with `buildHomeAssistantComponent`, installed via `customComponents`) removes the built-in Energy sidebar panel. HA offers no declarative way to hide it: `energy/async_setup` calls `frontend.async_register_built_in_panel` unconditionally in the same call that sets up the websocket API the `energy-*` cards and `EnergyCostSensor` depend on, and the component's `CONFIG_SCHEMA` is `cv.empty_config_schema`. The lovelace Energy view already renders the panel's content, so the panel is a duplicate. | HA gains a supported panel-visibility option (a `frontend` config key, or a per-panel `show_in_sidebar`) — then drop the custom integration |

---

## 4. Not deviations — build-config `.override`s (reference only)

These use `.override` / `.overrideAttrs` for normal customization, **not** to
depart from stock versions. Listed so a future audit doesn't re-flag them:

- `nixos-system/ollama.nix` — `ollama-cuda.override { cudaArches = [ "61" ]; }`
  (GTX 1060 / Pascal)
- `home-manager/shared/rofi.nix` — `rofi.override { plugins = [ rofi-calc ]; }`
- `nixos-system/home-assistant.nix` — `home-assistant.override { extraPackages = ... psycopg2 ... }`
  (the `doInstallCheck = false` part of the same expression **is** a workaround — see §3)

---

## 5. Flake inputs that don't track a 26.05 release

Most inputs `follows` nixpkgs or pin a `release-26.05` tag. These instead track
a rolling default branch, so they can move independently of the pinned channel
on `nix flake update`:

| Input | Tracks |
|---|---|
| `sops-nix` | `Mic92/sops-nix` default branch |
| `disko` | `nix-community/disko` default branch |
| `impermanence` | `nix-community/impermanence` default branch |
| `firefox-addons` | `rycee/nur-expressions` (rolling) |

Correctly pinned to 26.05 (no drift): `home-manager` (`release-26.05`).
Own repos: `finplanner`, `private`.

---

## Maintenance

- Adding a deviation? Add a row here in the same commit, with a concrete revert
  trigger.
- Removing one? Delete both the code and its row here.
- Periodic audit: `grep -rnE 'pkgs\.(unstable|pkgs-2505|pkgs-2105)|overrideAttrs|permittedInsecurePackages|allowInsecure' --include='*.nix' .`
  should turn up nothing that isn't documented above.
