{ config, pkgs, ... }: 

{

  programs.firefox = {
      enable = true;
      profiles.chris = {
        id = 0;
        name = "chris";
        bookmarks = {};
        extensions = with pkgs.inputs.firefox-addons; [
          ublock-origin
          bitwarden
          browserpass
        ];
        bookmarks = {

        };
        settings = {
          "browser.disableResetPrompt" = true;
          "browser.download.panel.shown" = true;
          "browser.download.useDownloadDir" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.defaultBrowserCheckCount" = 1;
          #"browser.search.defaultenginename" = "Searx";
          #"browser.search.order.1" = "Searx";
          "browser.startup.homepage" = "https://dcbond.com";
          "browser.uiCustomization.state" = ''{"placements":{"widget-overflow-fixed-list":[],"nav-bar":["back-button","forward-button","stop-reload-button","home-button","urlbar-container","downloads-button","library-button","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["save-to-pocket-button","developer-button","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"dirtyAreaCache":["nav-bar","PersonalToolbar","toolbar-menubar","TabsToolbar","widget-overflow-fixed-list"],"currentVersion":18,"newElementCount":4}'';
          "dom.security.https_only_mode" = true;
          "identity.fxaccounts.enabled" = false;
          "privacy.trackingprotection.enabled" = true;
          "signon.rememberSignons" = false;
        };
        #search = {

        #};
      };
    };
  
    home = {
      persistence = {
        # Not persisting is safer
        # "/persist/home/misterio".directories = [ ".mozilla/firefox" ];
      };
    };
  
    xdg.mimeApps.defaultApplications = {
      "text/html" = ["firefox.desktop"];
      "text/xml" = ["firefox.desktop"];
      "x-scheme-handler/http" = ["firefox.desktop"];
      "x-scheme-handler/https" = ["firefox.desktop"];
    };

}

#  programs = {
#    firefox = {
#      enable = true;
#      package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
#        extraPolicies = {
#          DisableTelemetry = true;
#          # EXTENSIONS
#          ExtensionSettings = {
#            "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
#            "uBlock0@raymondhill.net" = {
#              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
#              installation_mode = "force_installed";
#            };
#            # add extensions here...
#          };
#  
#          # PREFERENCES
#          Preferences = { 
#            "browser.contentblocking.category" = { Value = "strict"; Status = "locked"; };
#            "extensions.pocket.enabled" = lock-false;
#            "extensions.screenshots.disabled" = lock-true;
#            # add global preferences here...
#          };
#        };
#      };
#
#      # PROFILES
#      # Switch profiles via about:profiles page
#      # For options that are available in Home-Manager see https://nix-community.github.io/home-manager/options.html#opt-programs.firefox.profiles
#      profiles ={
#        profile_0 = {           # choose a profile name; directory is /home/<user>/.mozilla/firefox/profile_0
#          id = 0;               # 0 is the default profile; see also option "isDefault"
#          name = "chris";       # name as listed in about:profiles
#          #isDefault = true;     # can be omitted; true if profile ID is 0
#          settings = {          # specify profile-specific preferences here; check about:config for options
#            "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
#            "browser.startup.homepage" = "https://nixos.org";
#            "browser.newtabpage.pinned" = [{
#              title = "NixOS";
#              url = "https://nixos.org";
#            }];
#            # add preferences for profile_0 here...
#          };
#        };
#        #profile_1 = {
#        #  id = 1;
#        #  name = "profile_1";
#        #  isDefault = false;
#        #  settings = {
#        #    "browser.newtabpage.activity-stream.feeds.section.highlights" = true;
#        #    "browser.startup.homepage" = "https://ecosia.org";
#        #    # add preferences for profile_1 here...
#        #  };
#        #};
#      # add profiles here...
#      };
#    };
#  };
#
#}