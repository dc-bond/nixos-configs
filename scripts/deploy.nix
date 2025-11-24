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
  # Generate deployment script for a specific host
  mkDeployScript = hostname: hostConfig:
    let
      users = hostConfig.users;
      ipv4 = hostConfig.ipv4;
      
      # Generate age key setup commands for all users
      userAgeSetup = lib.concatMapStringsSep "\n" (user: ''
        # Setup age key for ${user}
        install -d -m700 "$temp/home/${user}/.config/age"
        pass users/${user}/age/private > "$temp/home/${user}/.config/age/${user}-age.key"
        chmod 600 "$temp/home/${user}/.config/age/${user}-age.key"
      '') users;
      
      # Generate UID retrieval for all users
      uidEvals = lib.concatMapStringsSep "\n" (user: 
        let 
          upperUser = lib.toUpper user;
          uid = toString configVars.users.${user}.uid;
        in ''${upperUser}_UID=${uid}''
      ) users;
      
      # Generate chown flags for all users
      chownFlags = lib.concatMapStringsSep " \\\n " (user:
        let upperUser = lib.toUpper user;
        in ''--chown /home/${user} ''${${upperUser}_UID}:100''
      ) users;
      
    in pkgs.writeShellScriptBin "deploy-${hostname}" ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      echo "Deploying ${hostname} to ${ipv4}..."
      
      # Create a temporary directory
      temp=$(mktemp -d)
      
      # Function to cleanup temporary directory on exit
      cleanup() {
        rm -rf "$temp"
      }
      trap cleanup EXIT
      
      # Create directory where sops expects to find the age host key
      install -d -m755 "$temp/etc/age"
      
      # Decrypt private system key from password store and copy to temp directory
      pass hosts/${hostname}/age/private > "$temp/etc/age/${hostname}-age.key"
      chmod 600 "$temp/etc/age/${hostname}-age.key"
      
      ${userAgeSetup}
      
      # Get UIDs from the flake configuration
      ${uidEvals}
      
      # Move to correct directory to generate hardware-configuration.nix
      cd "$HOME/nixos-configs/hosts/${hostname}"
      
      # Install with proper ownership
      nix run github:nix-community/nixos-anywhere -- \
        --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
        --disk-encryption-keys /tmp/crypt-passwd.txt <(pass hosts/${hostname}/disk-encryption-password) \
        --extra-files "$temp" \
        ${chownFlags} \
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