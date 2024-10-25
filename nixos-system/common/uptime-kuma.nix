{

  services.uptime-kuma = {
    enable = true;
  };

  services.traefik.dynamicConfigOptions.http.routers.uptime-kuma = {
    rule = "Host(`uptime-kuma.professorbond.com`)";
    service = "uptime-kuma";
    #middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "cloudflareDns";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.uptime-kuma = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:3001";
          #url = "https://uptime-kuma.professorbond.com:3001";
        }
      ];
    };
  };

}