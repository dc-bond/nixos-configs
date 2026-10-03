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
| `nixos-system/crowdsec.nix` | `crowdsec` | `pkgs.unstable` (1.8.1 vs 1.7.8 in 26.05) | **No-downgrade constraint.** juniper runs 1.8.1; 26.05 ships 1.7.8, so dropping the pin would move the local crowdsec DB *backwards* across a major version | 26.05 backports ≥1.8.1, or crowdsec state is deliberately rebuilt on the older major |
| `nixos-system/crowdsec.nix` | `crowdsec-firewall-bouncer` | `pkgs.unstable` (0.0.36) | Kept in lockstep with `crowdsec` above | Same as `crowdsec` |
| `nixos-system/unifi.nix` | `unifi` | `pkgs.unstable` (10.6.106 vs 10.2.105 in 26.05) | **No-downgrade constraint.** 26.05's 10.2.105 is *older* than the running 10.6.106, and UniFi migrates its config DB forward on upgrade: an older controller will not read it | 26.05 backports a `unifi` ≥ the running version |
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

**Revert trigger:** the channel reaching ≥ 3.x. Dropping the pin before then
would be a *major downgrade* of a tool in daily use.

---

## 2. Global overlays

Repo-wide package modifications in `overlays/default.nix`, applied to every
host via `nixos-system/foundation.nix` (`nixpkgs.overlays`).

None. The overlay file defines only the cross-channel package sets consumed
in §1: `pkgs.unstable` (nixos-unstable) and `pkgs.pkgs-2105` (21.05).

---

## 3. Config-level workarounds for upstream / 26.05 bugs

Not version pins, but deviations from a clean stock config, in place to work
around a specific bug. Each should be revisited when its linked issue closes.

| File | Workaround | Upstream reference / revert trigger |
|---|---|---|
| `nixos-system/crowdsec.nix` | Firewall-bouncer workaround — `preStart` touches `capi-credentials.yaml` / `lapi-credentials.yaml` before registration | [crowdsec#3632](https://github.com/crowdsecurity/crowdsec/issues/3632) |
| `nixos-system/crowdsec.nix` | **`crowdsec-firewall-bouncer-register.serviceConfig.StateDirectory` set to `"crowdsec-firewall-bouncer-register"` (`mkForce`), plus `ReadWritePaths = [ "/var/lib/crowdsec" ]`.** The 26.05 module puts `crowdsec` in that unit's `StateDirectory` ([`crowdsec-firewall-bouncer.nix:260`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/services/security/crowdsec-firewall-bouncer.nix)). The unit runs `DynamicUser`, so systemd would migrate `/var/lib/crowdsec` → `/var/lib/private/crowdsec` behind a symlink; `/var/lib/private` is `0700 root`, so `cscli` and anything else outside a service namespace cannot traverse it (`mkdir /var/lib/crowdsec: file exists`). A host whose state was already migrated needs the one-time repair in `MIGRATION-26.05.md` (private repo) | Upstream drops `crowdsec` from that unit's `StateDirectory`, or gives the register step a namespace-safe way to reach crowdsec's state. Re-test on the next channel bump |
| `nixos-system/crowdsec.nix` | **`environment.etc."crowdsec/config.yaml"`** mirrors the module's own `format.generate "crowdsec.yaml" cfg.settings.general`. The 26.05 register script invokes the *unwrapped* `cscli` (`lib.getExe' cfg.package "cscli"`, `crowdsec-firewall-bouncer.nix:234`), so it passes no `-c` and falls back to `/etc/crowdsec/config.yaml`, which nothing else populates (the config lives in the store). Without it registration fails, no `api-key.cred` is written, and the bouncer dies at `243/CREDENTIALS` with no `CROWDSEC_CHAIN` in iptables | Upstream restores the wrapped `cscli` (or passes `-c`) in the register script — then drop the `environment.etc` entry. **Fragile:** it duplicates one line of module internals, so re-check it whenever the crowdsec module changes |
| `nixos-system/crowdsec.nix` | Console-token auto-enrollment commented out | Possible upstream bug, untested on 26.05 — verify as part of bringing crowdsec to aspen (private repo `roadmap.txt`) |
| `nixos-system/home-assistant.nix` | `energy_panel_hide` custom integration (built with `buildHomeAssistantComponent`, installed via `customComponents`) removes the built-in Energy sidebar panel. HA offers no declarative way to hide it: `energy/async_setup` calls `frontend.async_register_built_in_panel` unconditionally in the same call that sets up the websocket API the `energy-*` cards and `EnergyCostSensor` depend on, and the component's `CONFIG_SCHEMA` is `cv.empty_config_schema`. The lovelace Energy view already renders the panel's content, so the panel is a duplicate. | HA gains a supported panel-visibility option (a `frontend` config key, or a per-panel `show_in_sidebar`) — then drop the custom integration |
| `nixos-system/fava.nix` | **`--read-only` omitted from fava's `ExecStart`.** Fava's read-only mode registers a `before_request` hook that `abort(401)`s any request whose method is not GET, and fava-dashboards 2.0.0b8 renders every panel through `POST .../extension/FavaDashboards/v1_render_panel`. With the flag set, each panel request gets a 401 HTML page, the frontend calls `response.json()` on it, and the browser reports `JSON.parse: unexpected character at line 1 column 1` — every panel blank. The abort fires before the extension's own error handler, so nothing reaches the journal and `journalctl -u fava` stays clean; the GET endpoints (`v2_config`, `v2_ledger`) still return 200, so the page frame loads normally. Dropping the flag does not make the ledger writable: the unit runs `ProtectSystem=strict` with no `ReadWritePaths`, so every path including the ledger is read-only to fava at the kernel level, and Traefik fronts it with `trusted-allow` (LAN plus named tailscale IPs) | fava-dashboards renders panels over GET again — 1.2.0 did, exposing only a GET `query` endpoint — or fava stops blocking extension POSTs in read-only mode. Then restore `--read-only`. 2.0.0b8 is a beta and treats the `dashboards.yaml` config as backwards compatibility, so re-check on the next fava-dashboards bump |

---

## 4. Not deviations — build-config `.override`s (reference only)

These use `.override` / `.overrideAttrs` for normal customization, **not** to
depart from stock versions. Listed so a future audit doesn't re-flag them:

- `nixos-system/ollama.nix` — `ollama-cuda.override { cudaArches = [ "61" ]; }`
  (GTX 1060 / Pascal)
- `nixos-system/sunshine.nix` — `sunshine.override { cudaSupport = true; }` with
  `CMAKE_CUDA_ARCHITECTURES=61`, for NVENC on the GTX 1060
- `home-manager/shared/rofi.nix` — `rofi.override { plugins = [ rofi-calc ]; }`

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
- Periodic audit: `grep -rnE 'pkgs\.(unstable|pkgs-2105)|overrideAttrs|permittedInsecurePackages|allowInsecure' --include='*.nix' .`
  should turn up nothing that isn't documented above.
