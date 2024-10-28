{

  services.uptime-kuma.enable = true; 

  services.traefik.dynamicConfigOptions.http = {
    routers.uptime-kuma = {
      entrypoints = ["websecure"];
      rule = "Host(`uptime-kuma.professorbond.com`)";
      service = "uptime-kuma";
      middlewares = [
        #"auth" 
        "secure-headers"
      ];
      tls = {
        certResolver = "cloudflareDns";
        options = "tls-13@file";
      };
    };
    services.uptime-kuma = {
      #settings = {
      #  PORT = "4100";
      #};
      loadBalancer = {
        passHostHeader = true;
        servers = [
        {
          url = "http://localhost:3001";
        }
        ];
      };
    };
  };

}