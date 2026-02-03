# Usage from NixOS ISO (booted on the target machine):
#   1. Connect to network
#   2. Run commands:
#        nix-shell -p gnupg pinentry-curses git pass
#          gpg --keyserver keyserver.ubuntu.com --recv-keys 012321D46E090E61
#          gpg --card-status
#          gpg --edit-key chris@dcbond.com  # trust -> 5 -> quit
#          git clone git@github.com:dc-bond/.password-store.git ~/.password-store && git clone https://github.com/dc-bond/nixos-configs.git ~/nixos-configs
#          pass show hosts/<hostname>/age/private # test
#          nix-shell ~/nixos-configs/scripts/bootstrap.nix
#          bootstrap-<hostname>  # e.g., bootstrap-thinkpad

{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
}:

let
  # load configVars from the parent directory
  configVars = import ../vars/default.nix { inherit lib; };

  # generate bootstrap script for a specific host
  mkBootstrapScript = hostname: hostConfig:
    let
      users = hostConfig.users;
      useDiskEncryption = hostConfig.hardware.diskEncryption or false;
      usesImpermanence = hostConfig.usesImpermanence or false;

      # paths depend on whether host uses impermanence
      etcAgePath = if usesImpermanence then "persist/etc/age" else "etc/age";
      homeBasePath = if usesImpermanence then "persist/home" else "home";

      # generate age key setup commands for all users
      userAgeSetup = lib.concatMapStringsSep "\n" (user: ''
        install -d -m700 "$temp/${homeBasePath}/${user}/.config/age"
        pass users/${user}/age/private > "$temp/${homeBasePath}/${user}/.config/age/${user}-age.key"
        chmod 600 "$temp/${homeBasePath}/${user}/.config/age/${user}-age.key"
      '') users;

      chownArgs = lib.concatMapStringsSep " \\\n    " (user:
        ''--chown /${homeBasePath}/${user} ${toString configVars.users.${user}.uid}:100''
      ) users;

    in pkgs.writeShellScriptBin "bootstrap-${hostname}" ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "Bootstrapping ${hostname} to localhost..."
      ${lib.optionalString useDiskEncryption ''echo "Using disk encryption for this host..."''}
      ${lib.optionalString usesImpermanence ''echo "Using impermanence architecture for this host..."''}

      # create a temporary directory for age keys
      temp=$(mktemp -d)
      trap "rm -rf $temp" EXIT

      # setup system age key
      install -d -m755 "$temp/${etcAgePath}"
      pass hosts/${hostname}/age/private > "$temp/${etcAgePath}/${hostname}-age.key"
      chmod 600 "$temp/${etcAgePath}/${hostname}-age.key"

      # setup user age key(s)
      ${userAgeSetup}

      # move to host directory (assumes standard clone location)
      cd "$HOME/nixos-configs/hosts/${hostname}"

      # run nixos-anywhere (identical to deploy.nix except target is localhost)
      ${if useDiskEncryption
        then ''
          nix run github:nix-community/nixos-anywhere -- \
            --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
            --disk-encryption-keys /tmp/crypt-passwd.txt <(pass hosts/${hostname}/disk-encryption-passwd) \
            --extra-files "$temp" \
            ${chownArgs} \
            --ssh-option StrictHostKeyChecking=no \
            --ssh-option UserKnownHostsFile=/dev/null \
            --ssh-option GlobalKnownHostsFile=/dev/null \
            --flake '.#${hostname}' \
            root@localhost
        ''
        else ''
          nix run github:nix-community/nixos-anywhere -- \
            --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
            --extra-files "$temp" \
            ${chownArgs} \
            --ssh-option StrictHostKeyChecking=no \
            --ssh-option UserKnownHostsFile=/dev/null \
            --ssh-option GlobalKnownHostsFile=/dev/null \
            --flake '.#${hostname}' \
            root@localhost
        ''
      }

      echo "Bootstrap deployment of ${hostname} complete!"
    '';

  # generate bootstrap scripts for all hosts
  bootstrapScripts = lib.mapAttrsToList mkBootstrapScript configVars.hosts;

in

# shell environment with all bootstrap scripts available
pkgs.mkShell {
  name = "nixos-bootstrap-environment";
  buildInputs = bootstrapScripts ++ [
    pkgs.git
    pkgs.gnupg
    pkgs.pass
    pkgs.pinentry-curses
  ];
}
