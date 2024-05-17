{ 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{
  home.packages = with pkgs; [
    #pcsclite # conflicts with gnupg's built-in scdaemon way of interfacing with smartcards?
    yubikey-personalization
    #yubikey-manager
    #yubioath-desktop # desktop tool to setup OTP codes on yubikey
  ];

  #environment.shellInit = ''
  #  export GPG_TTY="$(tty)"
  #  export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  #  gpgconf --launch gpg-agent
    #gpg-connect-agent /bye
    #export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  #'';

  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
    settings = {
      #use-agent = true; # to enable smartcard/ssh support?
      no-greeting = true;
      armor = true;
      no-emit-version = true;
      no-comments = true;
      no-symkey-cache = true;
      require-cross-certification = true;
      throw-keyids;
      with-fingerprint = true;
      default-key = "A8DD4B51A93E2D9C15B4D27F0419FDA34202A683";
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      keyserver = "hkps://keyserver.ubuntu.com";
      personal-cipher-preferences = "AES256 TWOFISH AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256 SHA224";
      cert-digest-algo = "SHA512";
      default-preference-list = "SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed";
    };
    scdaemonSettings = {
      disable-ccid = true;
    };
  };
  
  #services.ssh-agent.enable = false;
  #services.pcscd.enable = true;# conflicts with gnupg's built-in scdaemon way of interfacing with smartcards?
  #services.udev.packages = with pkgs; [ # goes in configuration.nix?
  #  yubikey-personalization
  #];
}

# NOTE IF USING MULTIPLE YUBIKEYS WITH SAME PRIVATE KEYS LOADED USE FOLLOWING TO SWITCH TO NEW YUBIKEY
# 'killall gpg-agent'
# 'rm -r ~/.gnupg/private-keys-v1.d/'
# 'gpg --card-status'