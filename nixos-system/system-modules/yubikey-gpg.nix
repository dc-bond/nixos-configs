{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gnupg
    pcsclite
    yubikey-personalization
  ];

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';

  programs.ssh.startAgent = false;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  
  services.pcscd.enable = true;

  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];
}