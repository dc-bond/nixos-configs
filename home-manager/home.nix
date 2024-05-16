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
    pfetch # system info on shell startup
    glances
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ls = "eza -all --long -g -h --color=always --group-directories-first --git";
      vim = "nvim";

      update = "sudo nixos-rebuild switch --flake ~/nixos-configs";
      #flake-update = "nix flake update ~/nixos-configs/flake.nix";
      #upgrade = "sudo nixos-rebuild switch --upgrade --flake ~/nixos-configs#thinkpad";

      configsys = "nvim ~/nixos-configs/system/configuration.nix";
      confighome = "nvim ~/nixos-configs/home-manager/home.nix";

      #addconfig = "cd ~/nixos-configs && git add . && cd ~";
      #pushconfig = "cd ~/nixos-configs && git add -A && git commit && git push --repo https://github.com/dc-bond/nixos-configs.git && cd ~";
    };
    initExtra = ''
      pfetch
      # eval "$(starship init zsh)"
    '';
    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "marlonrichert/zsh-autocomplete"; }
      ];
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
