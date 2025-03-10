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

  services = {

    ${app} = {
      enable = true;
      rootUsername = "${configVars.userEmail}";
      passwordSecret = "3LgC0W6UenLkPdPGhT94rO7V7Sar6RN2mN7DhNpi2kQHhON1TsA5QhZxdTHTijkdeMoPQTAtYElyxL8GlZkXVrb2dv2tNKEF";
      rootPasswordSha2 = "0ea98db27a78fd15d23172feb03e583ba9b055d21520ed6607eb331ac92bc570";
      #passwordSecret = config.sops.secrets.graylog-passwordSecret.path;
      #rootPasswordSha2 = config.sops.secrets.graylog-rootPasswordSha2.path;
      extraConfig = ''
        http_external_uri = https://${app}.${configVars.domain2}/
      '';
      elasticsearchHosts = [ "http://127.0.0.1:9200" ];
    };
    mongodb = {
      enable = true;
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