{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "wordpress-dcbond";
  app2 = "wordpress-dcbond-mysql";
in

{
  
  sops = {
    secrets = {
      wordpressDbUser = {};
      wordpressDbPasswd = {};
      wordpressDbName = {};
      wordpressMysqlRootPasswd = {};
      wordpressMysqlDb = {};
      wordpressMysqlUser = {};
      wordpressMysqlPasswd = {};
    };
    templates = {
      "${app}-env".content = ''
        WORDPRESS_DB_HOST=${app2}:3306
        WORDPRESS_DB_USER=${config.sops.placeholder.wordpressDbUser}
        WORDPRESS_DB_PASSWORD=${config.sops.placeholder.wordpressDbPasswd}
        WORDPRESS_DB_NAME=${config.sops.placeholder.wordpressDbName}
      '';
      "${app2}-env".content = ''
        MYSQL_ROOT_PASSWORD=${config.sops.placeholder.wordpressMysqlRootPasswd}
        MYSQL_DATABASE=${config.sops.placeholder.wordpressMysqlDb}
        MYSQL_USER=${config.sops.placeholder.wordpressMysqlUser}
        MYSQL_PASSWORD=${config.sops.placeholder.wordpressMysqlPasswd}
      '';
    };
  };

  virtualisation.oci-containers.containers = {

    "${app}" = {
      image = "docker.io/wordpress:6.7.1"; # https://hub.docker.com/_/wordpress/tags 
      autoStart = true;
      environmentFiles = [ config.sops.templates."${app}-env".path ];
      log-driver = "journald";
      volumes = [ "${app}:/var/www/html" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.wordpressDcbondIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.service" = "${app}";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.rule" = "Host(`${configVars.domain1}`)";
        "traefik.http.routers.${app}.tls" = "true";
        "traefik.http.routers.${app}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}.middlewares" = "secure-headers@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "80";
        "traefik.http.routers.${app}-admin.service" = "${app}-admin";
        "traefik.http.routers.${app}-admin.entrypoints" = "websecure";
        "traefik.http.routers.${app}-admin.rule" = "Host(`${configVars.domain1}`) && PathPrefix(`/wp-admin`)";
        "traefik.http.routers.${app}-admin.tls" = "true";
        "traefik.http.routers.${app}-admin.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}-admin.middlewares" = "secure-headers@file";
        "traefik.http.services.${app}-admin.loadbalancer.server.port" = "80";
      };
    };

    "${app2}" = {
      image = "docker.io/mysql:8.0.25"; # https://hub.docker.com/_/mysql/tags
      autoStart = true;
      log-driver = "journald";
      environmentFiles = [ config.sops.templates."${app2}-env".path ];
      volumes = [ "${app2}:/var/lib/mysql" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.wordpressDcbondMysqlIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

  };

  systemd = {
    services = { 

      "docker-${app}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-${app2}.service"
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
        ];
        requires = [
          "docker-${app2}.service"
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-network-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f ${app}";
        };
        script = ''
          docker network inspect ${app} || docker network create --subnet ${configVars.wordpressDcbondSubnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      "docker-volume-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app} || docker volume create ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      
      "docker-${app2}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-volume-${app2}.service"
          "docker-network-${app}.service"
        ];
        requires = [
          "docker-volume-${app2}.service"
          "docker-network-${app}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-volume-${app2}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app2} || docker volume create ${app2}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for docker-${app} container stack";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}