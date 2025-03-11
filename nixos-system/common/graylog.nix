{ 
pkgs,
config,
configVars, 
lib,
... 
}: 

let
  app = "graylog";
in

{

  networking.firewall.allowedUDPPorts = [ 12201 ];

  services = {

    ${app} = {
      enable = true;
      passwordSecret = "3LgC0W6UenLkPdPGhT94rO7V7Sar6RN2mN7DhNpi2kQHhON1TsA5QhZxdTHTijkdeMoPQTAtYElyxL8GlZkXVrb2dv2tNKEF";
      rootPasswordSha2 = "0ea98db27a78fd15d23172feb03e583ba9b055d21520ed6607eb331ac92bc570";
      rootUsername = "${configVars.userEmail}";
      extraConfig = ''
        http_external_uri = https://${app}.${configVars.domain2}/
        java.net.preferIPv4Stack = true
        root_timezone = America/New_York
        root_email = ${configVars.userEmail}
      '';
      elasticsearchHosts = [ "http://127.0.0.1:9200" ];
    };
    mongodb = {
      enable = true;
      package = pkgs.mongodb-ce;
    };
    opensearch = {
      enable = true;
      settings = {
        "cluster.name" = "graylog";
        "search.max_aggregation_rewrite_filters" = "0";
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [ "secure-headers" ];
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
            url = "http://127.0.0.1:9000";
          }
          ];
        };
      };
    };

  };

}