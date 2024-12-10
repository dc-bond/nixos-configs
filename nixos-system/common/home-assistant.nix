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

  services = {
    home-assistant = {
      enable = true;
      server_port = 8123;
      openFirewall = false;
      name = "19 Hemingway";
      longitude = "";
      latitude = "";
      temperature_unit = "F";
      time_zone = "America/New_York";
      unit_system = "metric";
    };
  };

}