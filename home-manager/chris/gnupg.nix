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

  # impermanence rebuilds ~/.gnupg on every boot, so the signing subkey's smartcard shadow stub in is missing until scdaemon first talks to the card - probe the yubikey on login so the stub exists before the first git commit signing attempt
  systemd.user.services.gpg-yubikey-learn = {
    Unit = {
      Description = "Probe YubiKey so gpg-agent learns smartcard keygrips";
      After = [ "gpg-agent.service" "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.gnupg}/bin/gpg --card-status";
      SuccessExitStatus = [ 0 2 ]; # don't fail if yubikey not plugged in
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

}