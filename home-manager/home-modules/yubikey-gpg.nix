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
    settings = {
      default-key = "A8DD4B51A93E2D9C15B4D27F0419FDA34202A683";
      no-greeting = true;
      armor = true;
      no-emit-version = true;
      no-comments = true;
      #keyid-format = "0xlong"
      with-fingerprint = true;
      #list-options = "show-uid-validity"
      #verify-options = "show-uid-validity"
      #use-agent
      #keyserver = "hkps://keyserver.ubuntu.com"
      #personal-cipher-preferences = "AES256 TWOFISH AES192 AES"
      #personal-digest-preferences = "SHA512 SHA384 SHA256 SHA224"
      #cert-digest-algo = "SHA512"
      #default-preference-list = "SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed"
    };
  };
  
  #services.pcscd.enable = true;

  #services.udev.packages = with pkgs; [
  #  yubikey-personalization
  #];
}
    #gpg-connect-agent /bye
    #export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)