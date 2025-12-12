{ 
  pkgs,
  config,
  configLib,
  configVars, 
  ... 
}: 

{

  home.packages = with pkgs; [
    (import (configLib.relativeToRoot "scripts/recover-email.nix") { inherit pkgs config; })
  ];

  home.file.".config/neomutt/mailcap".text = ''
    text/html; ${pkgs.firefox-esr}/bin/firefox-esr %s
  '';

  programs = {
    zsh.shellAliases."email" = "mbsync --all; notmuch new; neomutt";
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
    };
    neomutt = {
      enable = true;
      sourcePrimaryAccount = true;
      vimKeys = true;
      sort = "reverse-date-received";
      binds = [
        {
          action = "flag-message";
          key = "+";
          map = [ "index" "pager" ];
        }
        {
          action = "delete-message";
          key = "D";
          map = [ "index" "pager" ];
        }
        {
          action = "group-reply";
          key = "R";
          map = [ "index" "pager" ];
        }
        {
          action = "sync-mailbox";
          key = "s";
          map = [ "index" "pager" ];
        }
        {
          action = "sidebar-prev";
          key = "\\Ck";
          map = [ "index" "pager" ];
        }
        {
          action = "sidebar-next";
          key = "\\Cj";
          map = [ "index" "pager" ];
        }
        {
          action = "sidebar-open";
          key = "\\Co";
          map = [ "index" "pager" ];
        }
        {
          action = "display-message";
          key = "o";
          map = [ "index" ];
        }
      ];
      macros = [
        {
          action = "<enter-command>echo 'Synchronizing neomutt and exiting...'<enter><sync-mailbox><shell-escape>mbsync -a<enter><quit>";
          key = "q";
          map = [ "index" "pager" ];
        }
        {
          action = "<save-message>=Archive<enter>";
          key = "A";
          map = [ "index" "pager" ];
        }
        {
          action = "<view-attachments><search>text/html<enter><view-mailcap><exit>"; # view message in firefox
          key = "B";
          map = [ "index" ];
        }
      ];
      sidebar = {
        enable = true;
        width = 30;
        format = "%D%?F? [%F]?%* %?N?%N/?%S";
      };
      extraConfig = ''
        # general
        set wait_key = no
        set timeout = 3
        set mail_check = 0
        set delete
        set quit
        set thorough_search
        set mail_check_stats
        set wrap = 80
        set date_format = "%Y.%m.%d %H:%M"
        set index_format = "[%Z] %?X?A&-? %D  %-20.20F  %s"
        set uncollapse_jump
        set sort_re
        set send_charset = "utf-8:iso-8859-1:us-ascii"
        set charset = "utf-8"
        set mailcap_path = "~/.config/neomutt/mailcap"
        unset confirmappend
        unset move
        unset mark_old
        unset beep_new
        unset markers 

        # compose view options
        set edit_headers                     # show headers when composing
        set fast_reply                       # skip to compose when replying
        set askcc                            # ask for CC:
        set fcc_attach                       # save attachments with the body
        set forward_format = "Fwd: %s"       # format of subject when forwarding
        set forward_decode                   # decode when forwarding
        set attribution = "On %d, %n wrote:" # format of quoting header
        set reply_to                         # reply to Reply to: field
        set reverse_name                     # reply as whomever it was to
        set include                          # include message in replies
        set forward_quote                    # include message in forwards
        set editor = /usr/bin/nvim 
        set text_flowed
        unset mime_forward                   # forward attachments as part of body

        # sidebar
        set sidebar_next_new_wrap = yes
        set mail_check_stats = yes
        set sidebar_divider_char = ' | '

        # statusbar 
        set status_chars  = " *%A"
        set status_format = "[ Folder: %f ] [%r%m messages%?n? (%n new)?%?d? (%d to delete)?%?t? (%t tagged)? ]%>─%?p?( %p postponed )?"
        lists .*@lists.sr.ht

        # colors:
        color index yellow default '.*'
        color index_author red default '.*'
        color index_number blue default
        color index_subject cyan default '.*'
        color index brightyellow black "~N"
        color index_author brightred black "~N"
        color index_subject brightcyan black "~N"
        color header blue default ".*"
        color header brightmagenta default "^(From)"
        color header brightcyan default "^(Subject)"
        color header brightwhite default "^(CC|BCC)"
        mono bold bold
        mono underline underline
        mono indicator reverse
        mono error bold
        color normal default default
        color indicator brightblack white
        color sidebar_highlight brightblack white
        color sidebar_divider brightblack black
        color sidebar_flagged brightyellow black
        color sidebar_new green black
        color normal brightyellow default
        color error red default
        color tilde black default
        color message cyan default
        color markers red white
        color attachment white default
        color search brightmagenta default
        color status brightyellow black
        color hdrdefault brightgreen default
        color quoted green default
        color quoted1 blue default
        color quoted2 cyan default
        color quoted3 yellow default
        color quoted4 red default
        color quoted5 brightred default
        color signature brightgreen default
        color bold black default
        color underline black default
        color normal default default
        color body brightred default "[\-\.+_a-zA-Z0-9]+@[\-\.a-zA-Z0-9]+" # Email addresses
        color body brightblue default "(https?|ftp)://[\-\.,/%~_:?&=\#a-zA-Z0-9]+" # URL
        color body green default "\`[^\`]*\`" # Green text between ` and `
        color body brightblue default "^# \.*" # Headings as bold blue
        color body brightcyan default "^## \.*" # Subheadings as bold cyan
        color body brightgreen default "^### \.*" # Subsubheadings as bold green
        color body yellow default "^(\t| )*(-|\\*) \.*" # List items as yellow
        color body brightcyan default "[;:][-o][)/(|]" # emoticons
        color body brightcyan default "[;:][)(|]" # emoticons
        color body brightcyan default "[ ][*][^*]*[*][ ]?" # more emoticon?
        color body brightcyan default "[ ]?[*][^*]*[*][ ]" # more emoticon?
        color body red default "(BAD signature)"
        color body cyan default "(Good signature)"
        color body brightblack default "^gpg: Good signature .*"
        color body brightyellow default "^gpg: "
        color body brightyellow red "^gpg: BAD signature from.*"
        mono body bold "^gpg: Good signature"
        mono body bold "^gpg: BAD signature from.*"
        color body red default "([a-z][a-z0-9+-]*://(((([a-z0-9_.!~*'();:&=+$,-]|%[0-9a-f][0-9a-f])*@)?((([a-z0-9]([a-z0-9-]*[a-z0-9])?)\\.)*([a-z]([a-z0-9-]*[a-z0-9])?)\\.?|[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)(:[0-9]+)?)|([a-z0-9_.!~*'()$,;:@&=+-]|%[0-9a-f][0-9a-f])+)(/([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*(;([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*)*(/([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*(;([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*)*)*)?(\\?([a-z0-9_.!~*'();/?:@&=+$,-]|%[0-9a-f][0-9a-f])*)?(#([a-z0-9_.!~*'();/?:@&=+$,-]|%[0-9a-f][0-9a-f])*)?|(www|ftp)\\.(([a-z0-9]([a-z0-9-]*[a-z0-9])?)\\.)*([a-z]([a-z0-9-]*[a-z0-9])?)\\.?(:[0-9]+)?(/([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*(;([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*)*(/([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*(;([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*)*)*)?(\\?([-a-z0-9_.!~*'();/?:@&=+$,]|%[0-9a-f][0-9a-f])*)?(#([-a-z0-9_.!~*'();/?:@&=+$,]|%[0-9a-f][0-9a-f])*)?)[^].,:;!)? \t\r\n<>\"]"
      '';
    };
  };

  accounts.email = {
    maildirBasePath = "${config.home.homeDirectory}/email";
    accounts = {
      "${configVars.users.chris.email}" = {
        address = "${configVars.users.chris.email}";
        userName = "${configVars.users.chris.email}";
        realName = "${configVars.users.chris.fullName}";
        passwordCommand = "pass email/${configVars.users.chris.email}";
        primary = true;
        imap = {
          host = ${configVars.mailservers.namecheap.smtpHost};
          port = ${toString configVars.mailservers.namecheap.imapPort}; 
          tls = {
            enable = true; # TLS on port 993
            useStartTls = false;
          };
        };
        smtp = {
          host = ${configVars.mailservers.namecheap.smtpHost};
          port = ${toString configVars.mailservers.namecheap.smtpPort}; 
          tls = {
            enable = false; # TLS on port 465
            useStartTls = true; # STARTTLS on port 587
          };
        };
        msmtp.enable = true;
        notmuch = {
          enable = true;
          neomutt.enable = true; 
        };
        neomutt = {
          enable = true;
          showDefaultMailbox = false; # show "Inbox" in the sidebar
          mailboxType = "maildir"; 
          extraMailboxes = [ # show other mailboxes in the sidebar
            "Inbox"
            "Sent"
            "Drafts"
            "Spam"
            "Archive"
            "Trash"
          ];
        };
        mbsync = {
          enable = true;
          create = "maildir";
          groups = {
            "${configVars.users.chris.email}" = {
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
          key = "${configVars.users.chris.gpgKeyFingerprint}";
          signByDefault = true;
        };
      };
    };
  };
  
}