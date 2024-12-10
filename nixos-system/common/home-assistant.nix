{ 
  config, 
  pkgs, 
  configVars,
  ... 
}: 

{

  #sops.secrets = {
  #  #cloudflareApiKey = {
  #  #  owner = config.users.users.traefik.name;
  #  #  group = config.users.users.traefik.group;
  #  #  mode = "0440";
  #  #};
  #  #traefikBasicAuth = {
  #  #  owner = config.users.users.traefik.name;
  #  #  group = config.users.users.traefik.group;
  #  #  mode = "0440";
  #  #};
  #};

  networking.firewall.allowedTCPPorts = [
    8123
  ];

  services = {
    home-assistant = {
      enable = true;
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