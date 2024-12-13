{ 
  config, 
  pkgs, 
  configVars,
  ... 
}: 

{

  #networking.firewall.allowedTCPPorts = [ 8123 ];

  services = {

    home-assistant = {
      enable = true;
      #package = (pkgs.home-assistant.override {
      #  extraPackages = py: with py; [ psycopg2 ];
      #}).overrideAttrs (oldAttrs: {
      #  doInstallCheck = false;
      #});
      extraComponents = [
        "default_config"
        "esphome"
        "met"
        "radio_browser"
      ];
      config = {
        http.server_port = 8123;
        #recorder.db_url = "postgresql://@/homeassistant";
        #frontend = {
        #  themes = "!include_dir_merge_named themes";
        #};
        #homeassistant = {
        #  name = "Fort Hemingway";
        #  temperature_unit = "F";
        #  time_zone = "America/New_York";
        #  unit_system = "metric";
        #};
      };
    };

    #postgresql = {
    #  enable = true;
    #  ensureDatabases = [ "homeassistant" ];
    #  ensureUsers = [
    #    {
    #      name = "homeassistant";
    #      ensureDBOwnership = true;
    #      #ensureClauses.createdb = true;
    #    }
    #  ];
    #};

    #postgresqlBackup = { # postgres database backup
    #  enable = true;
    #  databases = [ "homeassistant" ];
    #  startAt = "*-*-* 01:00:00"; # daily starting at 1:00am
    #};

  };

}