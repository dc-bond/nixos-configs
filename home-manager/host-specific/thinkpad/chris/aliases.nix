{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbthink = "rebuild-local-thinkpad";
      rbcypress = "rebuild-remote-cypress";
      rbaspen = "rebuild-remote-aspen";
      getnets = "iwctl station wlan0 get-networks";
      flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
      vpnup = "ssh cypress 'sudo systemctl start docker-chromium-root.target'";
      vpndn = "ssh cypress 'sudo systemctl stop docker-chromium-root.target'";
      vpnrs = "ssh cypress 'sudo systemctl restart docker-chromium-root.target'";
    };
  };

}