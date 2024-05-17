{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    pcsclite
    yubikey-personalization
    #yubikey-manager
  ];

  #environment.shellInit = ''
  #  export GPG_TTY="$(tty)"
  #  export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  #  gpgconf --launch gpg-agent
  #'';

  #programs.ssh.startAgent = false;

  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
  };
  
  #services.pcscd.enable = true;

  #services.udev.packages = with pkgs; [
  #  yubikey-personalization
  #];
}
    #gpg-connect-agent /bye
    #export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)