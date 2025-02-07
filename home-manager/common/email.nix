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
      maildir.synchronizeFlags = true;
      new.tags = [
        "unread"
        "inbox"
      ];
      search.excludeTags = [
        "deleted"
        "spam"
      ];
      hooks.preNew = "mbsync --all";
    };
  };

  accounts.email.accounts = {
    "${configVars.userEmail}" = {
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
      notmuch.enable = true;
      mbsync = {
        enable = true;
        create = "maildir";
        groups = {
          "${configVars.userEmail}" = {
            channels = {
              "inbox" = {
                farPattern = "INBOX";
                nearPattern = "Inbox";
                extraConfig = {
                  Create = "both";
                  Expunge = "both";
                  SyncState = "*";
                };
              };
              "sent" = {
                farPattern = "Sent";
                nearPattern = "Sent";
                extraConfig = {
                  Create = "both";
                  Expunge = "both";
                  SyncState = "*";
                };
              };
              "drafts" = {
                farPattern = "Drafts";
                nearPattern = "Drafts";
                extraConfig = {
                  Create = "both";
                  Expunge = "both";
                  SyncState = "*";
                };
              };
              "spam" = {
                farPattern = "Spam";
                nearPattern = "Spam";
                extraConfig = {
                  Create = "both";
                  Expunge = "both";
                  SyncState = "*";
                };
              };
              "trash" = {
                farPattern = "Trash";
                nearPattern = "Trash";
                extraConfig = {
                  Create = "both";
                  Expunge = "both";
                  SyncState = "*";
                };
              };
            };
          };
        };
      };
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