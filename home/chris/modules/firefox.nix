{ 
  config,
  pkgs, 
  ... 
}: 

{

  programs.firefox = {
    enable = true;
    profiles = {

      default = {
        id = 0;
        name = "chris";
        path = "jribdwmn.default";
        isDefault = true;
        #settings = {
        #  "browser.startup.homepage" = "https://searx.aicampground.com";
        #  "browser.search.defaultenginename" = "Searx";
        #  "browser.search.order.1" = "Searx";
        #};
        #search = {
        #  force = true;
        #  default = "Searx";
        #  order = [ "Searx" "Google" ];
        #  engines = {
        #    "Nix Packages" = {
        #      urls = [{
        #        template = "https://search.nixos.org/packages";
        #        params = [
        #          { name = "type"; value = "packages"; }
        #          { name = "query"; value = "{searchTerms}"; }
        #        ];
        #      }];
        #      icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        #      definedAliases = [ "@np" ];
        #    };
        #    "NixOS Wiki" = {
        #      urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
        #      iconUpdateURL = "https://nixos.wiki/favicon.png";
        #      updateInterval = 24 * 60 * 60 * 1000; # every day
        #      definedAliases = [ "@nw" ];
        #    };
        #    "Searx" = {
        #      urls = [{ template = "https://searx.aicampground.com/?q={searchTerms}"; }];
        #      iconUpdateURL = "https://nixos.wiki/favicon.png";
        #      updateInterval = 24 * 60 * 60 * 1000; # every day
        #      definedAliases = [ "@searx" ];
        #    };
        #    "Bing".metaData.hidden = true;
        #    "Google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
        #  };
        #};
      }; # default

    }; # profiles
    policies = {
      BackgroundAppUpdate = false; 
      DisableBuiltinPDFViewer = false; # enabling potential security liability?
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true; # firefox sync
      #DisableFirefoxScreenshots = true; # No screenshots?
      #DisableForgetButton = true; # Thing that can wipe history for X time, handled differently
      #DisableMasterPasswordCreation = true; # to be determined how to handle master password
      DisableProfileImport = true; # only allow nix-defined profiles
      DisableProfileRefresh = true; # disable the Refresh Firefox button on about:support and support.mozilla.org
      DisableSetDesktopBackground = true; # remove the “Set As Desktop Background…” menuitem when right clicking on an image to avoid potential conflict with declarative nix configs
      DisplayMenuBar = "default-off";
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFormHistory = true;
      DisablePasswordReveal = true;
      DontCheckDefaultBrowser = true;
      HardwareAcceleration = true; # enabling exposes points for fingerprinting?
      OfferToSaveLogins = false;
	  	EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
        # Exceptions = ["https://example.com"]
        };
      EncryptedMediaExtensions = {
        Enabled = true;
        Locked = true;
      };
      #ExtensionUpdate = false;
      FirefoxHome = {
        Search = true;
        TopSites = false;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        SponsoredPocket = false;
        Snippets = false;
        Locked = true;
      };
      FirefoxSuggest = {
        WebSuggestions = false;
        SponsoredSuggestions = false;
        ImproveSuggest = false;
        Locked = true;
      };
      NoDefaultBookmarks = true;
      PasswordManagerEnabled = false; # managed by bitwarden
      PDFjs = {
        Enabled = false; # security liability
        EnablePermissions = false;
      };
      Permissions = {
        Camera = {
          #Allow = [https =//example.org,https =//example.org =1234];
          #Block = [https =//example.edu];
          BlockNewRequests = true;
          Locked = true;
        };
        Microphone = {
          #Allow = [https =//example.org];
          #Block = [https =//example.edu];
          BlockNewRequests = true;
          Locked = true;
        };
        Location = {
          #Allow = [https =//example.org];
          #Block = [https =//example.edu];
          BlockNewRequests = true;
          Locked = true;
        };
        Notifications = {
          #Allow = [https =//example.org];
          #Block = [https =//example.edu];
          BlockNewRequests = true;
          Locked = true;
        };
        #Autoplay = {
        #  #Allow = [https =//example.org];
        #  #Block = [https =//example.edu];
        #  #Default = allow-audio-video | block-audio | block-audio-video;
        #  Locked = true;
        #};
      };
      Handlers = {
        mimeTypes."application/pdf".action = "saveToDisk";
      };
      extensions = {
        pdf = {
          action = "useHelperApp";
      	  ask = true;
      	  handlers = [
      	  {
            name = "Zathura PDF Viewer";
            path = "${pkgs.zathura}/bin/zathura";
          }
      		];
      	};
      };

    }; # policies
    
  }; # programs.firefox
  
}