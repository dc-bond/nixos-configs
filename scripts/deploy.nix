# check ip on installation iso and update configVars
# set root password on installation iso with 'sudo passwd'


{ 
  pkgs,
  configVars,
  lib,
  ...
}:

let
  deployScript = pkgs.writeShellScriptBin "deploy-nixos" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    HOST="$1"
    
    ${lib.concatStringsSep "\n    " (lib.mapAttrsToList (hostname: hostConfig: ''
      if [ "$HOST" = "${hostname}" ]; then
        IPV4="''${2:-${hostConfig.ipv4}}"
        USERS=(${lib.concatStringsSep " " hostConfig.users})
      fi
    '') configVars.hosts)}
    
    temp=$(mktemp -d)
    trap "rm -rf $temp" EXIT
    
    install -d -m755 "$temp/etc/age"
    pass hosts/$HOST/age/private > "$temp/etc/age/$HOST-age.key"
    chmod 600 "$temp/etc/age/$HOST-age.key"
    
    CHOWN_ARGS=()
    for user in "''${USERS[@]}"; do
      install -d -m700 "$temp/home/$user/.config/age"
      pass users/$user/age/private > "$temp/home/$user/.config/age/$user-age.key"
      chmod 600 "$temp/home/$user/.config/age/$user-age.key"
      uid=$(nix eval --raw ".#nixosConfigurations.$HOST.config.users.users.$user.uid")
      CHOWN_ARGS+=(--chown "/home/$user" "$uid:100")
    done
    
    cd "$HOME/nixos-configs/hosts/$HOST"
    
    DISK_ENCRYPTION_ARGS=()
    if [[ " ''${USERS[*]} " =~ " eric " ]]; then
      DISK_ENCRYPTION_ARGS=(--disk-encryption-keys /tmp/crypt-passwd.txt <(pass users/eric/passwd))
    fi
    
    nix run github:nix-community/nixos-anywhere -- \
      --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
      "''${DISK_ENCRYPTION_ARGS[@]}" \
      --extra-files "$temp" \
      "''${CHOWN_ARGS[@]}" \
      --flake ".#$HOST" \
      root@$IPV4
  '';

in

{
  environment.systemPackages = [ deployScript ];
}