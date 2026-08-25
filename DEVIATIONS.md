# DEVIATIONS.md

Central registry of everything in this flake that is **not** a stock
`nixos-25.11` build: cross-channel package pulls, version pins, overlays,
insecure-package allowances, config-level workarounds for upstream bugs, and
flake inputs that don't track a 25.11 release.

**Why this file exists:** these deviations are otherwise scattered across the
tree with only inline comments, and it's easy to forget one is in place long
after the upstream reason is gone. When you add, change, or remove any of the
items below, update this file in the same commit. Each entry carries a
**revert trigger** — the condition under which the deviation should be dropped.

Paths are relative to `nixos-configs/`. Line numbers drift; grep the symbol if
a link is stale.

---

## 1. Active cross-channel / pinned package versions

Packages deliberately taken from a channel other than `nixpkgs` (25.11), or
pinned to a specific non-channel version.

| File | Package | Source instead of 25.11 | Reason | Revert trigger |
|---|---|---|---|---|
| `home-manager/shared/firefox.nix` | `bitwarden` | AMO XPI **2026.6.1** via `overrideAttrs` | Extension 2026.7.0 renders an empty vault against Vaultwarden 1.36.0 ([vaultwarden#7462](https://github.com/dani-garcia/vaultwarden/issues/7462)) | Vaultwarden server on **≥1.37.0** — then restore plain `bitwarden` |
| `nixos-system/sunshine.nix` | `sunshine` | `pkgs.pkgs-2505` (25.05) | 25.11 has an x11-capture crash regression ([nixpkgs#475181](https://github.com/NixOS/nixpkgs/issues/475181)) | Fix lands in 25.11 |
| `nixos-system/crowdsec.nix` | `crowdsec` | `pkgs.unstable` | Newer release than 25.11 ships | 25.11 catches up / no longer needed |
| `nixos-system/crowdsec.nix` | `crowdsec-firewall-bouncer` | `pkgs.unstable` | Kept in lockstep with `crowdsec` above | Same as `crowdsec` |
| `nixos-system/zigbee2mqtt.nix` | `zigbee2mqtt` | `pkgs.unstable` (2.13.0 at time of writing vs 2.6.3 in 25.11) | Current `ember` driver work for the SLZB-06MG24U's EFR32MG24 radio; 25.11's 2.6.3 predates several EmberZNet fixes | 25.11 ships ≥2.13.x — then drop back to `pkgs.zigbee2mqtt` |
| `home-manager/chris/icewind-dale.nix` | `openssl_1_0_2` | `pkgs.pkgs-2105` (21.05) | Beamdog game binary links libssl 1.0.0, removed from nixpkgs after 21.05 | **Permanent** by nature (legacy ABI) |
| `nixos-system/foundation.nix` | `librewolf` | `permittedInsecurePackages` (`librewolf-152.0.2-1`) | Allows a build flagged insecure so librewolf stays installable | Newer non-flagged librewolf in channel |

### Parity pulls from unstable (intentional, not bug workarounds)

`claude-code` is pinned to unstable so the CLI and the VSCodium extension stay
on matching versions:

- `home-manager/chris/claude-code.nix` (thinkpad + cypress),
  `home-manager/danielle/claude-code.nix` (kauri) —
  `programs.claude-code.package = pkgs.unstable.claude-code` (CLI, declarative module)
- `home-manager/chris/vscodium.nix`, `home-manager/danielle/vscodium.nix` —
  `pkgs.unstable.vscode-extensions.anthropic.claude-code`

**Revert trigger:** none — this is an ongoing preference, kept until 25.11's
`claude-code` is current enough that parity no longer requires unstable.

`mcp-nixos` (the NixOS/Home Manager MCP server wired into `claude-code` in
`home-manager/chris/claude-code.nix` and `home-manager/danielle/claude-code.nix`)
is pulled from unstable: 25.11 ships only
`1.0.3`, which predates the 2.x unified `nix()` tool surface and most data
sources. Uses `pkgs.unstable.mcp-nixos` (2.4.x).

**Revert trigger:** 25.11 backports `mcp-nixos` ≥ 2.x — then drop to `pkgs.mcp-nixos`.

---

## 2. Global overlays

Repo-wide package modifications in `overlays/default.nix`, applied to every
host via `nixos-system/foundation.nix` (`nixpkgs.overlays`).

| Package | What it does | Revert trigger |
|---|---|---|
| `matrix-synapse-unwrapped` | Blanks a typo'd `postPatch` that fails to match upstream `pyproject.toml`; the original substitution was a no-op anyway ([nixpkgs#530874](https://github.com/NixOS/nixpkgs/issues/530874)). Also sets `doCheck = false`: synapse 1.155.0's trial suite aborts with `twisted.protocols.amp.TooLong` under `trial -jN` on an oversized debug log line ([twisted#12482](https://github.com/twisted/twisted/issues/12482)) — a test-harness flake, not a runtime defect. The `postPatch` override already forces synapse to build locally (never substituted), so the suite runs on every rebuild here. | `postPatch`: nixpkgs#530874 fix lands. `doCheck`: 25.11 backports [synapse#19832](https://github.com/element-hq/synapse/pull/19832) or bumps past 1.155.0 — then restore checks. |
| `displaylink` | Pinned to **6.2** with a manual `requireFile` src + hash | Manual bump only; hash is mirrored in `nixos-system/rebuilds.nix` — keep the two in sync |
| `docker` | Pinned to the `docker_29` engine so all `pkgs.docker` references (oci-* units) use it | Deliberate engine pin; revisit on major docker bump |

The overlay file also defines the cross-channel package sets consumed in §1:
`pkgs.unstable` (nixos-unstable), `pkgs.pkgs-2505` (25.05), `pkgs.pkgs-2105`
(21.05).

---

## 3. Config-level workarounds for upstream / 25.11 bugs

Not version pins, but deviations from a clean stock config, in place to work
around a specific bug. Each should be revisited when its linked issue closes.

| File | Workaround | Upstream reference / revert trigger |
|---|---|---|
| `nixos-system/lldap.nix` | Passwords/JWT passed via `systemd` `LoadCredential` instead of the module's file-based settings (`*_file` options commented out) | File-based settings broken in 25.11 — restore the `*_file` options when fixed |
| `nixos-system/crowdsec.nix` | Firewall-bouncer workaround | [crowdsec#3632](https://github.com/crowdsecurity/crowdsec/issues/3632) |
| `nixos-system/crowdsec.nix` | Console-token auto-enrollment commented out | Possible upstream bug — re-test after settling on 25.11 |
| `nixos-system/yubikey.nix` | pcsclite polkit access-group workaround | [nixpkgs#121121](https://github.com/NixOS/nixpkgs/issues/121121) |
| `nixos-system/foundation.nix` | `nix.settings.nix-path = config.nix.nixPath` | [nix#9574](https://github.com/NixOS/nix/issues/9574) |
| `nixos-system/home-assistant.nix` | `doInstallCheck = false` on the HA package override | Drop when the install-check no longer fails |

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

## 5. Flake inputs that don't track a 25.11 release

Most inputs `follows` nixpkgs or pin a `release-25.11` tag. These instead track
a rolling default branch, so they can move independently of the pinned channel
on `nix flake update`:

| Input | Tracks |
|---|---|
| `sops-nix` | `Mic92/sops-nix` default branch |
| `disko` | `nix-community/disko` default branch |
| `impermanence` | `nix-community/impermanence` default branch |
| `firefox-addons` | `rycee/nur-expressions` (rolling) |

Correctly pinned to 25.11 (no drift): `home-manager` (`release-25.11`),
`simple-nixos-mailserver` (`nixos-25.11`). Own repos: `finplanner`, `private`.

---

## Maintenance

- Adding a deviation? Add a row here in the same commit, with a concrete revert
  trigger.
- Removing one? Delete both the code and its row here.
- Periodic audit: `grep -rnE 'pkgs\.(unstable|pkgs-2505|pkgs-2105)|overrideAttrs|permittedInsecurePackages|allowInsecure' --include='*.nix' .`
  should turn up nothing that isn't documented above.
