{ 
  pkgs,
  config,
  configVars,
  lib,
  ... 
}: 

{

  environment.systemPackages = with pkgs; [
    wl-clipboard # command-line copy/paste utilities for wayland
    libsecret # secrets library for gnome keyring
  ];

  programs = {
    labwc.enable = true;
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
    seahorse.enable = true; # gnome secrets managegement tool
    xfconf.enable = true; # enable xfconf to save preferences in thunar
  };

  services = {
    gnome.gnome-keyring.enable = true;
    gvfs.enable = true; # mount, trash, and other functionalities
    tumbler.enable = true; # thumbnail support for images
  };
  
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      source-code-pro
      source-sans-pro
      font-awesome
      nerd-fonts.sauce-code-pro
      nerd-fonts.fira-code
    ];
  };

}
