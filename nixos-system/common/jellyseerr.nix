{
  configVars,
  ...
}: 

let
  app = "jellyseerr";
in

{

  virtualisation.oci-containers.containers."${app}" = {
    image = "docker.io/fallenbagel/${app}:2.0.1";
    autoStart = true;
    #user = "1000:100";
    #volumes = [
    #  "/home/chris/oci-containers/${app}:/app/config"
    #];
    ports = [
      "5055:5055"
    ];
    #extraOptions = [
    #  "--init=true"
    #  "--label=traefik.enable=true"
    #  #"--label=traefik.docker.network=traefik"
    #  "--label=traefik.http.routers.${app}.entrypoints=websecure"
    #  "--label=traefik.http.routers.${app}.rule=Host(`${app}.${configVars.domain3}`)"
    #  "--label=traefik.http.routers.${app}.tls=true"
    #  "--label=traefik.http.routers.${app}.tls.options=tls-13@file"
    #  "--label=traefik.http.routers.${app}.middlewares=secure-headers@file"
    #  "--label=traefik.http.services.${app}.loadbalancer.server.port=5055"
    #];
  };
  
  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`${app}.${configVars.domain3}`)";
      service = "${app}";
      middlewares = [
        #"authelia" 
        "secure-headers"
      ];
      tls = {
        certResolver = "cloudflareDns";
        options = "tls-13@file";
      };
    };
    services.${app} = {
      loadBalancer = {
        passHostHeader = true;
        servers = [
        {
          url = "http://localhost:5055";
        }
        ];
      };
    };
  };

  #networking.firewall.allowedTCPPorts = [
  #  5055
  #];

}