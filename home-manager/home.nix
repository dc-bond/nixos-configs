{ pkgs, ... }:

{

  home.username = "chris";
  home.homeDirectory = "/home/chris";

  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    htop
    vim
    cowsay
  ];

}