{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
}:

let
  # load configVars from the parent directory
  # note: inputs is not available in bootstrap context, but vars/default.nix doesn't actually use it
  # pass an empty attrset to satisfy the function signature
  configVars = import ../vars/default.nix {
    inherit lib;
    inputs = {};
  };

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

      # run nixos-anywhere (identical to deploy.nix except target is localhost and experimental features enabled for ISO)
      ${if useDiskEncryption
        then ''
          nix --extra-experimental-features nix-command --extra-experimental-features flakes run github:nix-community/nixos-anywhere -- \
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
          nix --extra-experimental-features nix-command --extra-experimental-features flakes run github:nix-community/nixos-anywhere -- \
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