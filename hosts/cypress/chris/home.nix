{ 
  inputs, 
  config,
  lib,
  configLib,
  configVars,
  pkgs, 
  ... 
}: 

{
  
  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "home-manager/chris/zsh.nix"
      "home-manager/chris/starship.nix"
      "home-manager/chris/neovim.nix"
      "home-manager/chris/ssh.nix"
      "home-manager/chris/git.nix"
      "home-manager/chris/gnupg.nix"
      "home-manager/chris/pass.nix"

      "home-manager/chris/hyprland.nix"
    ])
  ];
  
  home.packages = with pkgs; [
    (import (configLib.relativeToRoot "scripts/get-pass-repo.nix") { inherit pkgs config; })
  ];

  programs = {
    home-manager.enable = true; # enable home manager
    zsh = {
      shellAliases = {
        storage = "cd /storage/WD-WX21DC86RU3P ; ls";
        ledger = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/bond-ledger/ && nix develop";
        speed = "nix run nixpkgs#speedtest-rs";
        tsaspen = "sudo tailscale down && sleep 5 && sudo tailscale up -ssh --accept-routes --exit-node=${configVars.aspenTailscaleIp}";
        tsjuniper = "sudo tailscale down && sleep 5 && sudo tailscale up -ssh --accept-routes --exit-node=${configVars.juniperTailscaleIp}";
      };
      initContent = ''

        reconnect-mouse() {
          echo "restarting bluetooth service..."
          sudo systemctl restart bluetooth
          sleep 3
          
          echo "power cycling bluetooth..."
          bluetoothctl power off
          sleep 2
          bluetoothctl power on
          sleep 3
          
          echo "reconnecting mouse..."
          bluetoothctl connect D3:CF:05:5D:88:79
          echo "Bluetooth reconnection complete!"
        }

        librewolf-private() {
          echo "launching LibreWolf..."
          librewolf --private-window "https://ipleak.net" "$@"
        }

      '';
    };
  };

# define username and home directory
  home = {
    username = configVars.chrisUsername;
    homeDirectory = "/home/${configVars.chrisUsername}";
  };

# define default folders in home directory
  xdg.userDirs = {
    enable = true;
    download = "${config.home.homeDirectory}/downloads";
    desktop = null;
  };

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "23.11";

}