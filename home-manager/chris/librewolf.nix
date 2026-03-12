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
    package = pkgs.librewolf;

    profiles = {
      default = {
        id = 0;
        name = username;
        path = "${username}.default";
        isDefault = true;

        extensions.packages = with firefox-addons; [
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
          };
        };
      };
    };

    policies = {
      # UI/UX preferences
      DisableFirefoxAccounts = false; # Enable Firefox Sync
      DisplayMenuBar = "default-off";
      DisplayBookmarksToolbar = "always";
      SearchBar = "unified";
      DontCheckDefaultBrowser = true;
      ShowHomeButton = false;
      # Homepage
      Homepage = {
        URL = "https://homepage.opticon.dev";
        Locked = true;
        StartPage = "homepage";
      };
      # Download behavior
      PromptForDownloadLocation = true;
      StartDownloadsInTempDirectory = true;
      # Media/DRM (LibreWolf may disable these)
      EncryptedMediaExtensions = {
        Enabled = true;
        Locked = true;
      };
      PictureInPicture = {
        Enabled = true;
        Locked = true;
      };
      # Hardware acceleration (important for WebGL)
      HardwareAcceleration = true;
      # Extension management
      ExtensionUpdate = false; # Managed by Nix
      # PDF viewer
      DisableBuiltinPDFViewer = false;
      PDFjs = {
        Enabled = true;
        EnablePermissions = false;
      };
      # Permissions
      Permissions = {
        Camera = {
          BlockNewRequests = false;
          Locked = false;
        };
        Microphone = {
          BlockNewRequests = false;
          Locked = false;
        };
        Location = {
          BlockNewRequests = true;
          Locked = true;
        };
        Notifications = {
          BlockNewRequests = true;
          Locked = true;
        };
        Autoplay = {
          Default = "allow-audio-video";
          Locked = true;
        };
      };
      # Search configuration
      SearchEngines = {
        PreventInstalls = true;
        Add = [
          {
            Name = "Bond-SearXNG";
            URLTemplate = "https://search.opticon.dev/?q={searchTerms}";
            Method = "GET";
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
      # Preferences - only non-privacy settings and WebGL fixes
      Preferences = {
        # Homepage/startup
        "browser.startup.page" = 1; # 1 = home
        "browser.startup.homepage" = "https://homepage.opticon.dev";
        "browser.startup.homepage_override.mstone" = "ignore"; # Prevent "What's New" page
        # Search bar
        "browser.urlbar.placeholderName" = "Opticon-SearXNG";
        "browser.search.defaultenginename" = "Opticon-SearXNG";
        # UI preferences
        "browser.aboutConfig.showWarning" = false;
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1; # compact mode
        "browser.download.autohideButton" = false;
        "browser.bookmarks.restore_default_bookmarks" = false;
        # Tab behavior
        "browser.tabs.loadInBackground" = true;
        "browser.tabs.hoverPreview.enabled" = true;
        # Session/crash recovery
        "browser.sessionstore.resume_from_crash" = true;
        # Firefox Sync
        "services.sync.engine.addons" = false; # Don't sync addons
        "services.sync.engine.prefs" = false; # Don't sync settings
        "services.sync.engine.prefs.modified" = false;
        "services.sync.engine.bookmarks" = true; # Do sync bookmarks
        "services.sync.declinedEngines" = "prefs,addons";
        # Extensions
        "extensions.autoDisableScopes" = 0; # Automatically enable extensions
        # WebGL and hardware acceleration
        "privacy.resistFingerprinting" = false; # Disable to fix WebGL
        "webgl.disabled" = false;
        "webgl.force-enabled" = true;
        "webgl.enable-webgl2" = true;
        "layers.acceleration.force-enabled" = true;
        "gfx.webrender.all" = true;
        "gfx.webrender.enabled" = true;
        # Performance optimization
        "browser.cache.disk.enable" = false; # Protect SSD, use RAM cache
        # Misc
        "mousewheel.system_scroll_override" = true;
      };
    };
  };

}