{ 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{
  home.packages = with pkgs; [
    #yubikey-personalization # tool required to make changes to yubikeys
    #yubikey-manager
    #yubioath-desktop # desktop tool to setup OTP codes on yubikey
    #pinentry-rofi # use rofi for gpg pinentry interface
  ];

  programs.gpg = {
    enable = true;
    homedir = "~/chris/.gnupg";
    #publicKeys = [
    #  {source = ${gpgKey}; trust = 5;}
    #];
    settings = {
      use-agent = true; # to enable smartcard/ssh support?
      no-greeting = true;
      armor = true;
      no-emit-version = true;
      no-comments = true;
      no-symkey-cache = true;
      require-cross-certification = true;
      throw-keyids = true;
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

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    #enableZshIntegration = true;
    #pinentryFlavor = "pinentry-rofi";
    #pinentryFlavor = "pinentry-curses";
    enableScDaemon = true;
  };
  
  #services.udev.packages = with pkgs; [ # goes in configuration.nix?
  #  yubikey-personalization
  #];
}

# NOTE IF USING MULTIPLE YUBIKEYS WITH SAME PRIVATE KEYS LOADED USE FOLLOWING TO SWITCH TO NEW YUBIKEY
# 'killall gpg-agent'
# 'rm -r ~/.gnupg/private-keys-v1.d/'
# 'gpg --card-status'