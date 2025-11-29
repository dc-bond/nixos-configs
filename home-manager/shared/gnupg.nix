{ 
  config,
  configLib,
  configVars,
  pkgs, 
  ... 
}: 

{

  programs.gpg = {
    enable = true;
    homedir = "${config.home.homeDirectory}/.gnupg";
    publicKeys = [ { text = configVars.users.chris.gpgPubKeyBlock; trust = 5; } ];
    settings = { 
      no-greeting = true;
      armor = true;
      no-emit-version = true;
      no-comments = true;
      no-symkey-cache = true;
      require-cross-certification = true;
      throw-keyids = true;
      with-fingerprint = true;
      default-key = "${configVars.users.chris.gpgKeyFingerprint}";
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
      disable-ccid = true; # disable gnupg's integrated CCID smartcard driver in favor of using system's smartcard reader (pcsclite package) PC/PD driver instead so no conflicts
    };
  };

}

      #{ source = (configLib.relativeToRoot "home-manager/chris/chrisGpgKey.pub"); trust = 5; }