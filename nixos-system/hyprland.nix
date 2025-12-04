{ 
  pkgs,
  lib,
  ... 
}: 

{

  environment = {
    systemPackages = with pkgs; [
      wl-clipboard # command-line copy/paste utilities for wayland
      libsecret # secrets library for gnome keyring
    ];
  };

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
    seahorse.enable = true; # gnome secrets managegement tool
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
    gnome.gnome-keyring.enable = true;
    gvfs.enable = true; # mount, trash, and other functionalities
    tumbler.enable = true; # thumbnail support for images
  };

}