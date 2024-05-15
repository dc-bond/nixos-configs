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
    glances
  ];

  programs.git = {
    enable = true;
    userName  = "Chris Bond";
    userEmail = "chris@dcbond.com";
  };

  # git remote add nixos-configs https://github.com/dc-bond/nixos-configs.git
  # git remote rm origin
  # git remote set-url nixos-configs git@github.com:dc-bond/nixos-configs.git 

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "23.11";
}