{ config, pkgs, ... }: 

{

 # gnupg 
  programs.gpg = {
    enable = true;
    homedir = "${config.home.homeDirectory}/.gnupg";
    publicKeys = [ 
      { source = ../DB9ADBBE6FBD1F0E694AF25D012321D46E090E61.pub; trust = 5; }
    ];
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
      disable-ccid = true;      
    };
  };

## zsh settings for gpg-agent
#  programs.zsh = {
    # added to zsh interactive shell to enable gpg-agent to serve ssh (.zshrc)
#    initExtra = ''
#      export GPG_TTY="$(tty)"
#      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
#      gpgconf --launch gpg-agent
#    '';
    # added to zsh environment shell to enable gpg-agent to serve ssh (.zshenv)
#    envExtra = ''
#      export GPG_TTY="$(tty)"
#      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
#      gpgconf --launch gpg-agent
#    '';
#  };

# disable ssh-agent
  services.ssh-agent.enable = false;

# gpg-agent
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableZshIntegration = true;
    #pinentryFlavor = "pinentry-rofi"; when enabling rofi in a compositor
    enableScDaemon = true;
  };

}