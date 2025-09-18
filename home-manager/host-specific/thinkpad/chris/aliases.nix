{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rb = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#thinkpad --refresh";
      flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
      getnets = "iwctl station wlan0 get-networks";
      ledger = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/bond-ledger/ && nix develop";
      speed = "nix run nixpkgs#speedtest-rs";
    };
  };

}