{ 
  config,
  pkgs, 
  ... 
}: 

{

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-esr;
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
      #BackgroundAppUpdate = false; 
      #DisableBuiltinPDFViewer = false; # enabling potential security liability?
      #DisableFirefoxStudies = true;
      #DisableFirefoxAccounts = true; # firefox sync
      ##DisableFirefoxScreenshots = true; # No screenshots?
      ##DisableForgetButton = true; # Thing that can wipe history for X time, handled differently
      ##DisableMasterPasswordCreation = true; # to be determined how to handle master password
      #DisableProfileImport = true; # only allow nix-defined profiles
      #DisableProfileRefresh = true; # disable the Refresh Firefox button on about:support and support.mozilla.org
      #DisableSetDesktopBackground = true; # remove the “Set As Desktop Background…” menuitem when right clicking on an image to avoid potential conflict with declarative nix configs
      #DisplayMenuBar = "default-off";
      #DisablePocket = true;
      #DisableTelemetry = true;
      #DisableFormHistory = true;
      #DisablePasswordReveal = true;
      #DontCheckDefaultBrowser = true;
      #HardwareAcceleration = true; # enabling exposes points for fingerprinting?
      #OfferToSaveLogins = false;
	  	#EnableTrackingProtection = {
      #  Value = true;
      #  Locked = true;
      #  Cryptomining = true;
      #  Fingerprinting = true;
      #  EmailTracking = true;
      #  # Exceptions = ["https://example.com"]
      #  };
      #EncryptedMediaExtensions = {
      #  Enabled = true;
      #  Locked = true;
      #};
      ##ExtensionUpdate = false;
      #FirefoxHome = {
      #  Search = true;
      #  TopSites = false;
      #  SponsoredTopSites = false;
      #  Highlights = false;
      #  Pocket = false;
      #  SponsoredPocket = false;
      #  Snippets = false;
      #  Locked = true;
      #};
      #FirefoxSuggest = {
      #  WebSuggestions = false;
      #  SponsoredSuggestions = false;
      #  ImproveSuggest = false;
      #  Locked = true;
      #};
      #NoDefaultBookmarks = true;
      #PasswordManagerEnabled = false; # managed by bitwarden
      #PDFjs = {
      #  Enabled = false; # security liability
      #  EnablePermissions = false;
      #};
      #Permissions = {
      #  Camera = {
      #    #Allow = [https =//example.org,https =//example.org =1234];
      #    #Block = [https =//example.edu];
      #    BlockNewRequests = true;
      #    Locked = true;
      #  };
      #  Microphone = {
      #    #Allow = [https =//example.org];
      #    #Block = [https =//example.edu];
      #    BlockNewRequests = true;
      #    Locked = true;
      #  };
      #  Location = {
      #    #Allow = [https =//example.org];
      #    #Block = [https =//example.edu];
      #    BlockNewRequests = true;
      #    Locked = true;
      #  };
      #  Notifications = {
      #    #Allow = [https =//example.org];
      #    #Block = [https =//example.edu];
      #    BlockNewRequests = true;
      #    Locked = true;
      #  };
      #  #Autoplay = {
      #  #  #Allow = [https =//example.org];
      #  #  #Block = [https =//example.edu];
      #  #  #Default = allow-audio-video | block-audio | block-audio-video;
      #  #  Locked = true;
      #  #};
      #};
      #Handlers = {
      #  #mimeTypes."application/pdf".action = "saveToDisk";
      #  extensions = {
      #    pdf = {
      #      action = "useHelperApp";
      #  	  ask = true;
      #  	  handlers = [
      #  	  {
      #        name = "Zathura PDF Viewer";
      #        path = "${pkgs.zathura}/bin/zathura";
      #      }
      #  		];
      #  	};
      #  };
      #};
      #PictureInPicture = {
      #  Enabled = true;
      #  Locked = true;
      #};
      #PromptForDownloadLocation = true;
      ##Proxy = {
      ##	Mode = "system"; # none | system | manual | autoDetect | autoConfig;
      ##	Locked = true;
      ##	# HTTPProxy = hostname;
      ##	# UseHTTPProxyForAllProtocols = true;
      ##	# SSLProxy = hostname;
      ##	# FTPProxy = hostname;
      ##	SOCKSProxy = "127.0.0.1:9050"; # Tor
      ##	SOCKSVersion = 5; # 4 | 5
      ##	#Passthrough = <local>;
      ##	# AutoConfigURL = URL_TO_AUTOCONFIG;
      ##	# AutoLogin = true;
      ##	UseProxyForDNS = true;
      ##};
      #SanitizeOnShutdown = {
      #  Cache = true;
      #  Cookies = false;
      #  Downloads = true;
      #  FormData = true;
      #  History = false;
      #  Sessions = false;
      #  SiteSettings = false;
      #  OfflineApps = true;
      #  Locked = true;
      #};
      #SearchEngines = {
      #  PreventInstalls = true;
      #  Add = [
      #    {
      #      Name = "BondSearch";
      #      URLTemplate = "https://search.opticon.dev";
      #      Method = "GET"; # GET | POST
      #      IconURL = "http://searx3aolosaf3urwnhpynlhuokqsgz47si4pzz5hvb7uuzyjncl2tid.onion/favicon.ico";
      #      # Alias = example;
      #      Description = "Bond SearXNG Instance";
      #      #PostData = name=value&q={searchTerms};
      #      #SuggestURLTemplate = https =//www.example.org/suggestions/q={searchTerms}
      #    }
      #  ];
      #  Remove = [
      #    "Amazon.com"
      #    "Bing"
      #    "Google"
      #    "DuckDuckGo"
      #    "eBay"
      #    "Wikipedia (en)"
      #  ];
      #  Default = "BondSearch";
      #};
      #SearchSuggestEnabled = false;
      #ShowHomeButton = false; # home button on the toolbar
      ##SSLVersionMax = tls1 | tls1.1 | tls1.2 | tls1.3;
      ##SSLVersionMin = tls1 | tls1.1 | tls1.2 | tls1.3;
      ##SSLVersionMin = "tls1.3";
      ##SupportMenu = {
      ##Title = Support Menu;
      ##URL = http =//example.com/support;
      ##AccessKey = S
      ##};
      #StartDownloadsInTempDirectory = true; # for speed? May fuck up the system on low ram
      #UserMessaging = {
      #  ExtensionRecommendations = false; # Don’t recommend extensions while the user is visiting web pages
      #    FeatureRecommendations = false; # Don’t recommend browser features
      #    Locked = true; # Prevent the user from changing user messaging preferences
      #    MoreFromMozilla = false; # Don’t show the “More from Mozilla” section in Preferences
      #    SkipOnboarding = true; # Don’t show onboarding messages on the new tab page
      #    UrlbarInterventions = false; # Don’t offer suggestions in the URL bar
      #    WhatsNew = false; # Remove the “What’s New” icon and menuitem
      #};
      #UseSystemPrintDialog = true;
      ##WebsiteFilter = {
      #  #Block = [<all_urls>];
      #  #Exceptions = [http =//example.org/*]
      ##};

    }; # policies
    
  }; # programs.firefox
  
}