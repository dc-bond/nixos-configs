{ 
pkgs,
lib,
... 
}: 

{

  programs = {
    hyprland = {
      enable = true;
      package = pkgs.hyprland;
    };
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
    xfconf.enable = true; # enable xfconf to save preferences in thunar
    firejail = {
      enable = true;
      wrappedBinaries = {
        librewolf = {
          executable = "${lib.getBin pkgs.librewolf}/bin/librewolf";
          profile = pkgs.writeText "librewolf-private.profile" ''
            include ${pkgs.firejail}/etc/firejail/librewolf.profile
            tmpfs ~/.librewolf
            tmpfs ~/.cache/librewolf
          '';
        };
      };
    };
  };

  services = {
    gvfs.enable = true; # mount, trash, and other functionalities
    tumbler.enable = true; # thumbnail support for images
  };

}