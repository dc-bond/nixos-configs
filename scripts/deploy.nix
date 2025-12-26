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
      
      # generate age key setup commands for all users
      userAgeSetup = lib.concatMapStringsSep "\n" (user: ''
        # Setup age key for ${user}
        install -d -m700 "$temp/home/${user}/.config/age"
        pass users/${user}/age/private > "$temp/home/${user}/.config/age/${user}-age.key"
        chmod 600 "$temp/home/${user}/.config/age/${user}-age.key"
      '') users;
      
    in pkgs.writeShellScriptBin "deploy-${hostname}" ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      echo "Deploying ${hostname} to ${ipv4}..."
      ${lib.optionalString useDiskEncryption ''echo "Using disk encryption for this host..."''}
      
      # create a temporary directory
      temp=$(mktemp -d)
      trap "rm -rf $temp" EXIT
      
      # setup system age key
      install -d -m755 "$temp/etc/age"
      pass hosts/${hostname}/age/private > "$temp/etc/age/${hostname}-age.key"
      chmod 600 "$temp/etc/age/${hostname}-age.key"
      
      ${userAgeSetup}
      
      # move to host directory
      cd "$HOME/nextcloud-client/Personal/nixos/nixos-configs/hosts/${hostname}"
      
      # build the nixos-anywhere command
      nix run github:nix-community/nixos-anywhere -- \
        --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
        ${lib.optionalString useDiskEncryption ''--disk-encryption-keys /tmp/crypt-passwd.txt <(pass hosts/${hostname}/disk-encryption-passwd) \''}
        --extra-files "$temp" \
        ${lib.concatMapStringsSep " \\\n  " (user: 
          ''--chown /home/${user} ${toString configVars.users.${user}.uid}:100''
        ) users} \
        --flake '.#${hostname}' \
        root@${ipv4}
      
      echo "Deployment of ${hostname} complete!"
    '';

  # Generate all deployment scripts
  deployScripts = lib.mapAttrsToList mkDeployScript configVars.hosts;
  
in

{
  environment.systemPackages = deployScripts;
}