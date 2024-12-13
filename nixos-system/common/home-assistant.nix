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
      #openFirewall = true;
      extraComponents = [
        "default_config"
        "esphome"
        "met"
        "radio_browser"
      ];
      #defaultIntegrations = [
      #  "application_credentials"
      #  "frontend"
      #  "hardware"
      #  "logger"
      #  "network"
      #  "system_health"
      #  "automation"
      #  "person"
      #  "scene"
      #  "script"
      #  "tag"
      #  "zone"
      #  "counter"
      #  "input_boolean"
      #  "input_button"
      #  "input_datetime"
      #  "input_number"
      #  "input_select"
      #  "input_text"
      #  "schedule"
      #  "timer"
      #  "backup"
      #];
      config = {
        http.server_port = 8123;
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
  };

}