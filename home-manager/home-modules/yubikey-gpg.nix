{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    #gnupg
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

  programs.gnupg.agent = {
    enable = true;
    #enableSSHSupport = true;
  };
  
  #services.pcscd.enable = true;

  #services.udev.packages = with pkgs; [
  #  yubikey-personalization
  #];
}
    #gpg-connect-agent /bye
    #export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)