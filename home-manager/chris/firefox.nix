{
  inputs,
  config,
  pkgs,
  ...
}:

let
  firefox-addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
  username = builtins.baseNameOf ./.;
in

{

  programs.firefox = {
    enable = true;
    package = pkgs.pkgs-2505.firefox-esr; # pinned to 25.05 because of bug
    profiles = {
      default = {
        id = 0;
        name = username;
        path = "${username}.default";
        isDefault = true;
        extensions.packages = with firefox-addons; [
          ublock-origin
          skip-redirect
          bitwarden
        ];
        search = {
          force = true;
          default = "Bond-SearXNG";
          order = [ "Bond-SearXNG" ];
          engines = {
            "Bond-SearXNG" = {
              urls = [{ template = "https://search.opticon.dev/?q={searchTerms}"; }];
              icon = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@searx" ];
            };
            "NixOS Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  { name = "type"; value = "packages"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "NixOS System Options" = {
              urls = [{
                template = "https://search.nixos.org/options";
                params = [
                  { name = "type"; value = "options"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };
            "NixOS Home-Manager Options" = {
              urls = [{
                template = "https://home-manager-options.extranix.com/";
                params = [
                  { name = "type"; value = "query"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@ho" ];
            };
            #"NixOS Wiki" = {
            #  urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
            #  icon = "https://nixos.wiki/favicon.png";
            #  updateInterval = 24 * 60 * 60 * 1000; # every day
            #  definedAliases = [ "@nw" ];
            #};
          };
        };
      };
    }; 
    policies = {
      BackgroundAppUpdate = false; 
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = false; # firefox sync
      DisableFirefoxScreenshots = true;
      DisableForgetButton = true;
      DisableMasterPasswordCreation = true;
      DisableProfileImport = true; # only allow nix-defined profiles
      DisableProfileRefresh = true; # disable the Refresh Firefox button on about:support and support.mozilla.org
      DisableSetDesktopBackground = true; # remove the “Set As Desktop Background…” menu item when right clicking on an image to avoid potential conflict with declarative nix configs
      DisplayMenuBar = "default-off"; # 'file, edit, view, etc. right-click menubar at top of screen
      DisplayBookmarksToolbar = "always";
      SearchBar = "unified";
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFormHistory = true;
      DisablePasswordReveal = true;
      DisablePrivateBrowsing = true; # no need
      HttpsOnlyMode = "force_enabled";
      DontCheckDefaultBrowser = true;
      HardwareAcceleration = true; # enabling exposes points for fingerprinting?
      OfferToSaveLogins = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      #OverrideFirstRunPage = ""; # breaks firefox if no profile folder exists in filesystem?
	  	EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
        # Exceptions = ["https://example.com"]
      };
      Cookies = {
        Behavior = "reject-tracker-and-partition-foreign";
        Locked = true;
      };
      Preferences = {
        "browser.startup.homepage" = "https://search.opticon.dev";
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.openpage" = false;
        "browser.urlbar.suggest.recentsearches" = false;
        "browser.urlbar.placeholderName" = "Opticon-SearXNG";
        "browser.search.defaultenginename" = "Opticon-SearXNG";
        "browser.aboutConfig.showWarning" = false; # no warning when going to config
        "browser.topsites.contile.enabled" = "lock-false";
        "browser.compactmode.show" = true; # show compact mode as an option in the customize toolbar menu
        "browser.uidensity" = 1; # set compact mode layout density
        "browser.cache.disk.enable" = false; # be kind to hard drive
        "browser.tabs.loadInBackground" = true; # load tabs automaticlaly
        "browser.tabs.hoverPreview.enabled" = true; # enable new preview tabs feature as of 129.0
        "browser.newtabpage.pinned" = "lock-false";
        "browser.newtabpage.activity-stream.showSponsored" = "lock-false";
        "browser.newtabpage.activity-stream.system.showSponsored" = "lock-false";
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = "lock-false";
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = "lock-false";
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = "lock-false";
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.snippets" = "lock-false";
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
        "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.havePinned" = "";
        "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.searchEngines" = "";
        "browser.download.autohideButton" = false; # never hide downloads button
        "browser.bookmarks.restore_default_bookmarks" = false;
			  "browser.sessionstore.resume_from_crash" = true;
        "services.sync.engine.addons" = false; # don't sync addons
        "services.sync.engine.prefs" = false; # don't sync settings
        "services.sync.engine.prefs.modified" = false; # don't sync more settings
        "services.sync.engine.bookmarks" = true; # sync bookmarks
        "services.sync.declinedEngines" = "prefs,addons"; # decline more
        "mousewheel.system_scroll_override" = true;
        "extensions.autoDisableScopes" = 0; # automatically enable extensions
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
			  "privacy.resistFingerprinting" = true;
			  #"privacy.resistFingerprinting.letterboxing" = true;
			  "privacy.globalprivacycontrol.enabled" = true;
			  "privacy.donottrackheader.enabled" = true;
        #"browser.uiCustomization.state" =
        #''
        #  {
        #    "placements":
        #    {
        #      "widget-overflow-fixed-list":[],
        #      "unified-extensions-area":
        #      [
        #        "ublock0_raymondhill_net-browser-action"
        #      ],
        #      "nav-bar":
        #      [
        #        "back-button",
        #        "forward-button",
        #        "stop-reload-button",
        #        "urlbar-container",
        #        "downloads-button",
        #        "fxa-toolbar-menu-button",
        #        "unified-extensions-button"
        #      ],
        #      "toolbar-menubar":["menubar-items"],
        #      "TabsToolbar":
        #      [
        #        "firefox-view-button",
        #        "tabbrowser-tabs",
        #        "new-tab-button"
        #      ],
        #      "PersonalToolbar":["personal-bookmarks"]
        #    },
        #    "currentVersion":20,
        #    "newElementCount":3
        #  }
        #'';
      };
      EncryptedMediaExtensions = {
        Enabled = true;
        Locked = true;
      };
      DNSOverHTTPS = { # handled at system level
        Enabled = false;
        #ProviderURL = "URL_TO_ALTERNATE_PROVIDER";
        Locked = true;
        #ExcludedDomains = ["example.com"];
        #Fallback = true | false;
      };
      ExtensionUpdate = false; # disable automatic updates of extensions because controlled by nix instead
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
      DisableBuiltinPDFViewer = false; # built-in pdf viewer
      PDFjs = { # built-in pdf viewer
        Enabled = true;
        EnablePermissions = false;
      };
      Permissions = {
        Camera = {
          #Allow = [https =//example.org,https =//example.org =1234];
          #Block = [https =//example.edu];
          BlockNewRequests = false;
          Locked = false;
        };
        Microphone = {
          #Allow = [https =//example.org];
          #Block = [https =//example.edu];
          BlockNewRequests = false;
          Locked = false;
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
        Autoplay = {
          #Allow = [https =//example.org];
          #Block = [https =//example.edu];
          #Default = allow-audio-video | block-audio | block-audio-video;
          Default = "allow-audio-video";
          Locked = true;
        };
      };
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
      PictureInPicture = {
        Enabled = true;
        Locked = true;
      };
      PromptForDownloadLocation = true;
      #Proxy = {
      #	#Mode = "manual"; # none | system | manual | autoDetect | autoConfig;
      #	Mode = "none"; # none | system | manual | autoDetect | autoConfig;
      #	Locked = false;
      #	HTTPProxy = ""; # server running squid proxy
      #	UseHTTPProxyForAllProtocols = false;
      #	#SSLProxy = hostname;
      #	#FTPProxy = hostname;
      #	#SOCKSProxy = "127.0.0.1:9050"; # Tor
      #	SOCKSVersion = 5; # 4 | 5
      #	Passthrough = ""; # homeassistant and possibly other containers not setup for proxy through vpn
      #	#AutoConfigURL = URL_TO_AUTOCONFIG;
      #	#AutoLogin = true;
      #	#UseProxyForDNS = true;
      #};
      SanitizeOnShutdown = {
        Cache = true;
        Cookies = true;
        Downloads = true;
        FormData = true;
        History = true;
        Sessions = true;
        SiteSettings = true;
        OfflineApps = true;
        Locked = true;
      };
      SearchEngines = {
        PreventInstalls = true;
        Add = [
          {
            Name = "Bond-SearXNG";
            URLTemplate = "https://search.opticon.dev/?q={searchTerms}"; # accessible through vpn only
            Method = "GET"; # GET | POST
            Description = "Bond Private Self-Hosted SearXNG Instance";
          }
        ];
        Remove = [
          "Amazon.com"
          "eBay"
          "Google"
          "Bing"
          "DuckDuckGo"
          "Wikipedia (en)"
        ];
        Default = "Bond-SearXNG";
      };
      SearchSuggestEnabled = false;
      ShowHomeButton = false; # home button on the toolbar
      #SSLVersionMax = tls1 | tls1.1 | tls1.2 | tls1.3;
      #SSLVersionMin = tls1 | tls1.1 | tls1.2 | tls1.3;
      SSLVersionMin = "tls1.2";
      StartDownloadsInTempDirectory = true; # for speed, may cause issues if low memory
      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        Locked = true;
        MoreFromMozilla = false;
        SkipOnboarding = true;
        UrlbarInterventions = false;
        WhatsNew = false;
      };
      UseSystemPrintDialog = false; # use firefox print-preview instead of system print popup dialogue
    };
  }; 
  
}