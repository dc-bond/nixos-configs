{ 
  config, 
  pkgs, 
  ... 
}: 

{

  programs.gpg = {
    enable = true;
    homedir = "${config.home.homeDirectory}/.gnupg";
    publicKeys = [ 
      { source = ../chrisGpgKey.pub; trust = 5; }
    ];
    settings = { 
      no-greeting = true;
      armor = true;
      no-emit-version = true;
      no-comments = true;
      no-symkey-cache = true;
      require-cross-certification = true;
      throw-keyids = true;
      with-fingerprint = true;
      default-key = "DB9ADBBE6FBD1F0E694AF25D012321D46E090E61";
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

  services.ssh-agent.enable = false; # ensure ssh-agent is not running
  
  services.gpg-agent = {
    enable = true; # this setting adds export GPG_TTY lines to user's .zshrc and starts the agent on login
    enableScDaemon = true; # allow gpg-agent to use smartcards (e.g. yubikey)
    enableSshSupport = true; # this setting adds 'gpg-connect-agent updatestartuptty /bye' to user's .zshrc to replace ssh-agent SSH_AUTH_SOCK with gpg-agent instead
    sshKeys = [ # adds keygrip identifier to .gnupg/sshcontrol file and load gpg auth private key into gpg-agent
      "DB9ADBBE6FBD1F0E694AF25D012321D46E090E61"
    ];
    pinentryPackage = pkgs.pinentry-tty;
  };

}
