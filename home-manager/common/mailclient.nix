{ 
  pkgs,
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
      gpg = {
        key = "${userGpgPubKey}";
        signByDefault = true;
      };
      imap = {
        host = "mail.privateemail.com";
        port = 993; 
      };
      smtp = {
        host = "mail.privateemail.com";
        port = 465; 
        tls.enable = true;
        useStartTls = false;
      };
      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "both";
        #extraConfig
      };
      msmtp.enable = true;
      notmuch.enable = true;
      primary = true;
      realName = "${configVars.userFullName}";
      signature = {
        text = ''
          Chris Bond
        '';
        delimiter = ''
        - - -
        '';
        showSignature = "append";
      };
      passwordCommand = "pass email/${configVars.userEmail}";
      userName = "${configVars.userEmail}";
    };
  };
  
}