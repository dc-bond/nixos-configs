# Stage 1 learning artifact for the backup-verification toolkit.
#
# What this is
# ------------
# A single-machine nixosTest with nginx serving a static "hello" page.
# The point isn't the service — it's to give you a small, fast-booting
# VM you can drive interactively from a Python REPL, so you learn the
# nixos-test-driver API before that API starts wrapping real backup
# restores.
#
# What this is NOT (yet)
# ----------------------
# * No shared directory — the VM has nothing bind-mounted from the host
# * No borg extraction — production probes wrap this primitive in a
#   script that first extracts an archive to a scratch dir
# * No systemd timer, no metric emission, no failure notifications
# * testScript is a stub because you drive the machine interactively
#
# How this evolves toward production
# ----------------------------------
# Stage 2: add `virtualisation.sharedDirectories.restore.source = ...;`
#          so extracted data lands at /mnt/restore inside the VM
# Stage 3: swap nginx for a real service + a testScript that restores
#          data + hits a health endpoint
# Stage 4: wrap the whole thing in backup-verification.nix so a rotation
#          timer runs it nightly against real archives
#
# ─── runbook (run on aspen) ────────────────────────────────────────────
#
#   # build the interactive driver (produces ./result)
#   cd ~/nixos/nixos-configs
#   nix build .#learnVm
#
#   # start the REPL — sudo for /dev/kvm access
#   sudo ./result/bin/nixos-test-driver
#
#   # in the Python REPL:
#   >>> machine.start()                          # boot the VM
#   >>> machine.wait_for_unit("nginx.service")   # block until nginx is up
#   >>> machine.wait_for_open_port(80)
#   >>> machine.succeed("curl -sf http://localhost")
#   >>> machine.shell_interact()                 # drop into a shell in the VM
#                                                #   ↑ Ctrl-] to exit
#   >>> machine.get_screen_text()                # capture serial console text
#   >>> machine.shutdown()                       # graceful shutdown
#   >>> exit()                                   # leave the REPL
#
#   # cleanup
#   rm result
#
# ────────────────────────────────────────────────────────────────────────

{ pkgs }:

pkgs.nixosTest {
  name = "learn-nixostest";

  nodes.machine = { config, pkgs, lib, ... }: {

    # keep the VM small — this is a learning box, not a service host
    virtualisation = {
      memorySize = 512;
      cores = 1;
    };

    # a trivial service to poke at from the REPL
    services.nginx = {
      enable = true;
      virtualHosts.default = {
        default = true;
        extraConfig = ''
          location / {
            return 200 "hello from nixosTest\n";
          }
        '';
      };
    };

    # firewall off so curl from inside the VM works without extra rules;
    # the VM has no external network exposed anyway
    networking.firewall.enable = false;
  };

  # only runs when the driver is invoked non-interactively;
  # left non-empty so batch mode is a sensible smoke test if you try it
  testScript = ''
    machine.wait_for_unit("nginx.service")
    machine.wait_for_open_port(80)
    machine.succeed("curl -sf http://localhost | grep -q hello")
  '';
}
