# check ip on installation iso and update configVars
# set root password on installation iso with 'sudo passwd'

{ 
  pkgs,
  config,
  configVars,
  lib,
  ...
}:

let
  # generate deployment script for a specific host
  mkDeployScript = hostname: hostConfig:
    let
      users = hostConfig.users;
      ipv4 = hostConfig.networking.ipv4;
      useDiskEncryption = hostConfig.hardware.diskEncryption or false;
      usesImpermanence = hostConfig.usesImpermanence or false;

      # paths depend on whether host uses impermanence to ensure age keys are deployed to persistent storage on installation; bind mounts (early and via impermanence module tooling) in impermanence.nix make keys available where sops expects them at runtime
      etcAgePath = if usesImpermanence then "persist/etc/age" else "etc/age";
      homeBasePath = if usesImpermanence then "persist/home" else "home";

      # generate age key setup commands for all users
      userAgeSetup = lib.concatMapStringsSep "\n" (user: ''
        install -d -m700 "$temp/${homeBasePath}/${user}/.config/age"
        pass users/${user}/age/private > "$temp/${homeBasePath}/${user}/.config/age/${user}-age.key"
        chmod 600 "$temp/${homeBasePath}/${user}/.config/age/${user}-age.key"
      '') users;
      
    in pkgs.writeShellScriptBin "deploy-${hostname}" ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      echo "Deploying ${hostname} to ${ipv4}..."
      ${lib.optionalString useDiskEncryption ''echo "Using disk encryption for this host..."''}
      ${lib.optionalString usesImpermanence ''echo "Using impermanence architecture for this host..."''}

      # create a temporary directory
      temp=$(mktemp -d)
      trap "rm -rf $temp" EXIT

      # setup system age key
      install -d -m755 "$temp/${etcAgePath}"
      pass hosts/${hostname}/age/private > "$temp/${etcAgePath}/${hostname}-age.key"
      chmod 600 "$temp/${etcAgePath}/${hostname}-age.key"

      # setup user age key(s)
      ${userAgeSetup}
      
      # move to host directory
      cd "$HOME/nextcloud-client/Personal/nixos/nixos-configs/hosts/${hostname}"
      
      # build the nixos-anywhere command, bypass declarative knownHosts to allow deployment to fresh installation ISOs
      ${if useDiskEncryption
        then ''
          nix run github:nix-community/nixos-anywhere -- \
            --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
            --disk-encryption-keys /tmp/crypt-passwd.txt <(pass hosts/${hostname}/disk-encryption-passwd) \
            --extra-files "$temp" \
            ${lib.concatMapStringsSep " \\\n    " (user:
              ''--chown /${homeBasePath}/${user} ${toString configVars.users.${user}.uid}:100''
            ) users} \
            --ssh-option StrictHostKeyChecking=no \
            --ssh-option UserKnownHostsFile=/dev/null \
            --ssh-option GlobalKnownHostsFile=/dev/null \
            --flake '.#${hostname}' \
            root@${ipv4}
        ''
        else ''
          nix run github:nix-community/nixos-anywhere -- \
            --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
            --extra-files "$temp" \
            ${lib.concatMapStringsSep " \\\n    " (user:
              ''--chown /${homeBasePath}/${user} ${toString configVars.users.${user}.uid}:100''
            ) users} \
            --ssh-option StrictHostKeyChecking=no \
            --ssh-option UserKnownHostsFile=/dev/null \
            --ssh-option GlobalKnownHostsFile=/dev/null \
            --flake '.#${hostname}' \
            root@${ipv4}
        ''
      }
      
      echo "Deployment of ${hostname} complete!"
    '';

  # Generate all deployment scripts
  deployScripts = lib.mapAttrsToList mkDeployScript configVars.hosts;
  
in

{
  environment.systemPackages = deployScripts;
}