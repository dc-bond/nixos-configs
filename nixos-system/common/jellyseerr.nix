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
    volumes = [
      "/home/${configVars.userName}/container-data/${app}:/app/config"
    ];
    extraOptions = [
      "--network=backend"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.${app}.entrypoints" = "websecure";
      "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain3}`)";
      "traefik.http.routers.${app}.tls" = "true";
      "traefik.http.routers.${app}.tls.options" = "tls-13@file";
      "traefik.http.routers.${app}.middlewares" = "secure-headers@file";
      "traefik.http.services.${app}.loadbalancer.server.port" = "5055";
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/${configVars.userName}/container-data/${app} 0770 ${configVars.userName} users -"
  ];
  
  #networking.firewall.allowedTCPPorts = [
  #  5055
  #];

}