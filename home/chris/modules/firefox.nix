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
        settings = {
          "browser.startup.homepage" = "https://search.opticon.dev";
          "browser.search.defaultenginename" = "Opticon-SearXNG";
          "browser.search.order.1" = "Opticon-SearXNG";
        };
        search = {
          force = true;
          default = "Opticon-SearXNG";
          order = [ "Opticon-SearXNG" ];
          engines = {
            "Opticon-SearXNG" = {
              urls = [{ template = "https://search.opticon.dev/?q={searchTerms}"; }];
              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@searx" ];
            };
            "Nix Packages" = {
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
            "NixOS Wiki" = {
              urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@nw" ];
            };
            #"Home Manager Options" = {
						#	urls = [{	
            #    template = "https://mipmip.github.io/home-manager-option-search";
						#		params = [ 
            #      { name = "query"; value = "{searchTerms}"; } 
            #    ];
						#	}];
            #  iconUpdateURL = "https://nixos.wiki/favicon.png";
						#	updateInterval = 24 * 60 * 60 *1000; # every day
						#	definedAliases = [ "@hm" ];
						#};
          };
        };
        #bookmarks = [
        #  {
        #    name = "Bookmarks Toolbar"
        #  }          
        #];

      }; # default

    }; # profiles
    policies = {
      BackgroundAppUpdate = false; 
      #DisableBuiltinPDFViewer = false; # enabling potential security liability?
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true; # firefox sync
      DisableFirefoxScreenshots = true;
      DisableForgetButton = true;
      DisableMasterPasswordCreation = true;
      DisableProfileImport = true; # only allow nix-defined profiles
      DisableProfileRefresh = true; # disable the Refresh Firefox button on about:support and support.mozilla.org
      DisableSetDesktopBackground = true; # remove the “Set As Desktop Background…” menuitem when right clicking on an image to avoid potential conflict with declarative nix configs
      DisplayMenuBar = "default-off"; # 'file, edit, view, etc. right-click menubar at top of screen
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
      #ExtensionSettings = with builtins;
      #  let extension = shortId: uuid: {
      #    name = uuid;
      #    value = {
      #      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      #      installation_mode = "normal_installed";
      #    };
      #  };
      #  in listToAttrs [
      #    #(extension "tree-style-tab" "treestyletab@piro.sakura.ne.jp")
      #    (extension "ublock-origin" "uBlock0@raymondhill.net")
      #    (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}")
      #    #(extension "tabliss" "extension@tabliss.io")
      #    #(extension "umatrix" "uMatrix@raymondhill.net")
      #    #(extension "libredirect" "7esoorv3@alefvanoon.anonaddy.me")
      #    #(extension "clearurls" "{74145f27-f039-47ce-a470-a662b129930a}")
      #  ];
      #  # To add additional extensions, find it on addons.mozilla.org, find
      #  # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
      #  # Then, download the XPI by filling it in to the install_url template, unzip it,
      #  # run `jq .browser_specific_settings.gecko.id manifest.json` or
      #  # `jq .applications.gecko.id manifest.json` to get the UUID
      #};
			#ExtensionSettings = {
			#	"*" = {
			#		installation_mode = "blocked";
			#		blocked_install_message = "NOPE";
			#	};
			#	"uBlock0@raymondhill.net" = {
      #    install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
      #    installation_mode = "force_installed";
			#	};
			#};
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
        Autoplay = {
          #Allow = [https =//example.org];
          #Block = [https =//example.edu];
          #Default = allow-audio-video | block-audio | block-audio-video;
          Default = "allow-audio-video";
          Locked = true;
        };
      };
      Handlers = {
        #mimeTypes."application/pdf".action = "saveToDisk";
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
      };
      PictureInPicture = {
        Enabled = true;
        Locked = true;
      };
      PromptForDownloadLocation = true;
      #Proxy = {
      #	Mode = "system"; # none | system | manual | autoDetect | autoConfig;
      #	Locked = true;
      #	# HTTPProxy = hostname;
      #	# UseHTTPProxyForAllProtocols = true;
      #	# SSLProxy = hostname;
      #	# FTPProxy = hostname;
      #	SOCKSProxy = "127.0.0.1:9050"; # Tor
      #	SOCKSVersion = 5; # 4 | 5
      #	#Passthrough = <local>;
      #	# AutoConfigURL = URL_TO_AUTOCONFIG;
      #	# AutoLogin = true;
      #	UseProxyForDNS = true;
      #};
      SanitizeOnShutdown = {
        Cache = true;
        Cookies = false;
        Downloads = true;
        FormData = true;
        History = false;
        Sessions = false;
        SiteSettings = false;
        OfflineApps = true;
        Locked = true;
      };
      SearchEngines = {
        PreventInstalls = true;
        Add = [
          {
            Name = "Opticon-SearXNG";
            URLTemplate = "https://search.opticon.dev/?q={searchTerms}"; # accessible through vpn only
            Method = "GET"; # GET | POST
            Description = "Opticon Self-Hosted SearXNG Instance";
          }
        ];
        Remove = [
          "Google"
          "Amazon.com"
          "Bing"
          "DuckDuckGo"
          "eBay"
          "Wikipedia (en)"
        ];
        Default = "SearXNG";
      };
      SearchSuggestEnabled = false;
      ShowHomeButton = false; # home button on the toolbar
      #SSLVersionMax = tls1 | tls1.1 | tls1.2 | tls1.3;
      #SSLVersionMin = tls1 | tls1.1 | tls1.2 | tls1.3;
      SSLVersionMin = "tls1.2";
      #SupportMenu = {
      #Title = Support Menu;
      #URL = http =//example.com/support;
      #AccessKey = S
      #};
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
      #WebsiteFilter = {
        #Block = [<all_urls>];
        #Exceptions = [http =//example.org/*]
      #};

    }; # policies
    
  }; # programs.firefox
  
}