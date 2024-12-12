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
      extraComponents = [
      "esphome"
      "met"
      "radio_browser"
      ];
      #configWritable = true;
      config = {
        http.server_port = 8123;
        frontend = {
          themes = "!include_dir_merge_named themes";
        };
        homeassistant = {
          name = "Fort Hemingway";
          temperature_unit = "F";
          time_zone = "America/New_York";
          unit_system = "metric";
        };
      };
    };
  };

}