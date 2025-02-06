{ 
  pkgs,
  config,
  configVars, 
  ... 
}: 

{

  programs = {
    mbsync.enable = true;
    msmtp.enable = true;
    notmuch = {
      enable = true;
      hooks.preNew = "mbsync --all";
    };
  };

  accounts.email.accounts = {
    dcbond = {
      address = "${configVars.userEmail}";
      userName = "${configVars.userEmail}";
      realName = "${configVars.userFullName}";
      passwordCommand = "pass email/${configVars.userEmail}";
      primary = true;
      imap = {
        host = "mail.privateemail.com";
        port = 993; 
        tls = {
          enable = true;
          useStartTls = false;
        };
      };
      smtp = {
        host = "mail.privateemail.com";
        port = 465; 
        tls = {
          enable = true;
          useStartTls = false;
        };
      };
      msmtp.enable = true;
      notmuch = {
        enable = true;
        #neomutt.enable = true; 
      };
      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "both";
      };
      maildir.path = "${config.home.homeDirectory}/email";
      #neomutt = {
      #  enable = true;
      #};
      signature = {
        text = ''
          Chris Bond
        '';
        delimiter = ''
        - - -
        '';
        showSignature = "append";
      };
      gpg = {
        key = "${configVars.userGpgPubKey}";
        signByDefault = true;
      };
    };
  };
  
}