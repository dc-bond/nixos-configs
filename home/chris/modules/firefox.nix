{ 
  inputs,
  config,
  pkgs, 
  ... 
}: 

let
  firefox-addons = inputs.firefox-addons.packages.${pkgs.system};
in

{

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-esr;
    profiles = {
      default = {
        id = 0;
        name = "chris";
        path = "chris.default";
        isDefault = true;
        extensions = with firefox-addons; [
          #darkreader
          #refined-github
          #violentmonkey
          privacy-badger
          #clearurls
          #decentraleyes
          #libredirect
          #no-pdf-download
          ublock-origin
          bitwarden
        ];
        settings = {
          #"browser.startup.homepage" = "https://search.opticon.dev";
          #"browser.search.defaultenginename" = "Opticon-SearXNG";
          #"browser.search.order.1" = "Opticon-SearXNG";
			    #"privacy.resistFingerprinting" = true;
			    #"privacy.resistFingerprinting.letterboxing" = true;
			    #"privacy.globalprivacycontrol.enabled" = true;
			    #"privacy.donottrackheader.enabled" = true;
			    #"privacy.clearOnShutdown.history" = true;
			    #"privacy.clearOnShutdown.downloads" = true;
			    #"webgl.disabled" = true;
			    #"browser.preferences.defaultPerformanceSettings.enabled" = false;
			    #"browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
			    #"browser.sessionstore.resume_from_crash" = true;
			    #"layers.acceleration.disabled" = true;
			    #"network.trr.mode" = 3;
			    #"network.dns.disableIPv6" = true;
			    #"media.autoplay.blocking_policy" = 2;
          
          "gfx.webrender.all" = true; # force enable GPU acceleration
          "media.ffmpeg.vaapi.enabled" = true;
          "widget.dmabuf.force-enabled" = true;

          #"reader.parse-on-load.force-enabled" = true; # reader functionality force on

          ## Hide the "sharing indicator", it's especially annoying
          ## with tiling WMs on wayland
          #"privacy.webrtc.legacyGlobalIndicator" = false;

          ## Actual settings
          #"app.shield.optoutstudies.enabled" = false;
          #"app.update.auto" = false;
          #"browser.bookmarks.restore_default_bookmarks" = false;
          #"browser.contentblocking.category" = "strict";
          #"browser.ctrlTab.recentlyUsedOrder" = false;
          #"browser.discovery.enabled" = false;
          #"browser.laterrun.enabled" = false;
          #"browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" =
          #  false;
          #"browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" =
          #  false;
          #"browser.newtabpage.activity-stream.feeds.snippets" = false;
          #"browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.havePinned" = "";
          #"browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.searchEngines" = "";
          #"browser.newtabpage.activity-stream.section.highlights.includePocket" =
          #  false;
          #"browser.newtabpage.activity-stream.showSponsored" = false;
          #"browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          #"browser.newtabpage.pinned" = false;
          #"browser.protections_panel.infoMessage.seen" = true;
          #"browser.quitShortcut.disabled" = true;
          #"browser.shell.checkDefaultBrowser" = false;
          #"browser.ssb.enabled" = true;
          #"browser.toolbars.bookmarks.visibility" = "never";
          #"browser.urlbar.placeholderName" = "DuckDuckGo";
          #"browser.urlbar.suggest.openpage" = false;
          #"datareporting.policy.dataSubmissionEnable" = false;
          #"datareporting.policy.dataSubmissionPolicyAcceptedVersion" = 2;
          #"dom.security.https_only_mode" = true;
          #"dom.security.https_only_mode_ever_enabled" = true;
          #"extensions.getAddons.showPane" = false;
          #"extensions.htmlaboutaddons.recommendations.enabled" = false;
          #"extensions.pocket.enabled" = false;
          #"identity.fxaccounts.enabled" = false;
          #"privacy.trackingprotection.enabled" = true;
          #"privacy.trackingprotection.socialtracking.enabled" = true;
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
      #BackgroundAppUpdate = false; 
      #DisableBuiltinPDFViewer = false; # enabling potential security liability?
      #DisableFirefoxStudies = true;
      #DisableFirefoxAccounts = true; # firefox sync
      #DisableFirefoxScreenshots = true;
      #DisableForgetButton = true;
      #DisableMasterPasswordCreation = true;
      #DisableProfileImport = true; # only allow nix-defined profiles
      #DisableProfileRefresh = true; # disable the Refresh Firefox button on about:support and support.mozilla.org
      #DisableSetDesktopBackground = true; # remove the “Set As Desktop Background…” menuitem when right clicking on an image to avoid potential conflict with declarative nix configs
      #DisplayMenuBar = "default-off"; # 'file, edit, view, etc. right-click menubar at top of screen
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
      #};
      #EncryptedMediaExtensions = {
      #  Enabled = true;
      #  Locked = true;
      #};
      #ExtensionUpdate = false; # disable automatic updates of extensions because controlled by nix instead
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
      #  Autoplay = {
      #    #Allow = [https =//example.org];
      #    #Block = [https =//example.edu];
      #    #Default = allow-audio-video | block-audio | block-audio-video;
      #    Default = "allow-audio-video";
      #    Locked = true;
      #  };
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
      #      Name = "Opticon-SearXNG";
      #      URLTemplate = "https://search.opticon.dev/?q={searchTerms}"; # accessible through vpn only
      #      Method = "GET"; # GET | POST
      #      Description = "Opticon Self-Hosted SearXNG Instance";
      #    }
      #  ];
      #  Remove = [
      #    "Google"
      #    "Amazon.com"
      #    "Bing"
      #    "DuckDuckGo"
      #    "eBay"
      #    "Wikipedia (en)"
      #  ];
      #  Default = "Opticon-SearXNG";
      #};
      #SearchSuggestEnabled = false;
      #ShowHomeButton = false; # home button on the toolbar
      #SSLVersionMax = tls1 | tls1.1 | tls1.2 | tls1.3;
      #SSLVersionMin = tls1 | tls1.1 | tls1.2 | tls1.3;
      #SSLVersionMin = "tls1.2";
      #SupportMenu = {
      #Title = Support Menu;
      #URL = http =//example.com/support;
      #AccessKey = S
      #};
      #StartDownloadsInTempDirectory = true; # for speed, may cause issues if low memory
      #UserMessaging = {
      #  ExtensionRecommendations = false;
      #  FeatureRecommendations = false;
      #  Locked = true;
      #  MoreFromMozilla = false;
      #  SkipOnboarding = true;
      #  UrlbarInterventions = false;
      #  WhatsNew = false;
      #};
      #UseSystemPrintDialog = false; # use firefox print-preview instead of system print popup dialogue
      #WebsiteFilter = {
        #Block = [<all_urls>];
        #Exceptions = [http =//example.org/*]
      #};

    }; # policies
    
  }; # programs.firefox
  
}