{

  services.uptime-kuma.enable = true; 
  #services.uptime-kuma = {
  #  enable = true;
  #  #loadBalancer.servers.url = "https://uptime-kuma.professorbond.com:3001";
  #};

  services.traefik.dynamicConfigOptions.http = {
    routers.uptime-kuma = {
      entrypoints = ["websecure"];
      rule = "Host(`uptime-kuma.professorbond.com`)";
      service = "uptime-kuma";
      #middlewares = ["headers"];
      tls.certResolver = "cloudflareDns";
    };
    services.uptime-kuma = {
      loadBalancer = {
        passHostHeader = true;
        servers.url = "http//localhost:3001";
      };
    };
  };

}