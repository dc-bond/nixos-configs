{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
  ];

  nixpkgs = {
    overlays = [
    ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "chris";
    homeDirectory = "/home/chris";
  };

  home.packages = with pkgs; [
    htop
    neovim
  ];

  programs.git = {
    enable = true;
    userName  = "Chris Bond";
    userEmail = "chris@dcbond.com";
  };

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "23.11";
}