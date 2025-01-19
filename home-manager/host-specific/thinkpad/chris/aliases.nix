{ 
  pkgs, 
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
      #borglistcypress = "sudo borg list /var/lib/borg-backups/cypress";
      borginfocypress = "sudo borg info /var/lib/borg-backups/cypress";
    };
  };

}