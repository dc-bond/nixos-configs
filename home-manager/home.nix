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
    eza # modern replacement for 'ls'
    glances
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    #autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      #ls = "ls -alh";
      ls = "eza -all --long -g -h --color=always --group-directories-first --git";
      rebuild = "sudo nixos-rebuild switch --flake /home/chris/nixos-configs";
    };
    history.size = 5000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };

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
