{ 
  self, 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "chris@dcbond.com";
      dnsProvider = "cloudflare";
      environmentFile = "/REPLACE/WITH/YOUR/PATH"; # location of CLOUDFLARE_DNS_API_TOKEN
    };
  };

  services = {
    nginx.virtualHosts = {
      "YOUR.DOMAIN.NAME" = {
        forceSSL = true;
        enableACME = true;
        acmeRoot = null; # use dns challenge
      };
    };
     
    nextcloud = {
      enable = true;
      hostName = "YOUR.DOMAIN.NAME";
      package = pkgs.nextcloud29; # manually increment with upgrades
      database.createLocally = true; # creates database
      configureRedis = true; # creates redis instance
      maxUploadSize = "10G"; # max upload size
      https = true;
      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; { # list of nextcloud apps
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
        inherit calendar contacts notes onlyoffice tasks cookbook qownnotesapi;
        #socialsharing_telegram = pkgs.fetchNextcloudApp rec { # custom app example
        #  url =
        #    "https://github.com/nextcloud-releases/socialsharing/releases/download/v3.0.1/socialsharing_telegram-v3.0.1.tar.gz";
        #  license = "agpl3";
        #  sha256 = "sha256-8XyOslMmzxmX2QsVzYzIJKNw6rVWJ7uDhU1jaKJ0Q8k=";
        #};
      };
      settings = {
        overwriteProtocol = "https";
        default_phone_region = "US";
      };
      config = {
        dbtype = "pgsql"; # postgres databse
        adminuser = "admin";
        adminpassFile = "/REPLACE/WITH/YOUR/PATH";
      };
      phpOptions."opcache.interned_strings_buffer" = "16"; # suggested by nextcloud's health check
    };
    postgresqlBackup = { # nightly databse backup
      enable = true;
      startAt = "*-*-* 01:15:00";
    };
  };

}