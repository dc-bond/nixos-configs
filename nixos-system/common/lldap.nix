{
  pkgs,
  lib,
  config,
  configVars,
  ...
}: 

let
  app = "lldap";
  db = "postgres";
in

{

  sops.secrets = {
    lldapJwtSecret = {};
    lldapLdapUserPasswd = {};
    lldapLdapDatabaseUrl = {};
    lldapPostgresPasswd = {};
    lldapPostgresUser = {};
    lldapPostgresDb = {};
  };
  sops.templates = {
    "${app}-env".content = ''
      UID=1000
      GID=1000
      TZ=America/New_York
      LLDAP_JWT_SECRET=${config.sops.placeholder.lldapJwtSecret}
      LLDAP_LDAP_USER_PASS=${config.sops.placeholder.lldapLdapUserPasswd}
      LLDAP_DATABASE_URL=${config.sops.placeholder.lldapLdapDatabaseUrl}
      LLDAP_LDAP_BASE_DN=dc=professorbond,dc=com
    '';
    "${db}-env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder.lldapPostgresPasswd}
      POSTGRES_USER=${config.sops.placeholder.lldapPostgresUser}
      POSTGRES_DB=${config.sops.placeholder.lldapPostgresDb}
    '';
  };

  #systemd.tmpfiles.rules = [
  #  "d /home/${configVars.userName}/container-data/${app} 0770 ${configVars.userName} users -"
  #];

  virtualisation.oci-containers.containers = {
    "${app}" = {
      image = "docker.io/nitnelave/${app}:2024-01-05";
      autoStart = true;
      log-driver = "journald";
      ports = [
        "3890:3890" # ldap port
      ]; 
      volumes = [
        #"/home/${configVars.userName}/container-data/${app}/${app}:/data"
        "${app}:/data"
      ];
      environmentFiles = [config.sops.templates."${app}-env".path];
      extraOptions = [
        "--network=${app}"
      ];
      dependsOn = ["${db}-${app}"];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain3}`)";
        "traefik.http.routers.${app}.tls" = "true";
        "traefik.http.routers.${app}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}.middlewares" = "secure-headers@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "17170"; # web frontend port
      };
    };
    "${db}-${app}" = {
      image = "docker.io/library/${db}:12-alpine";
      autoStart = true;
      log-driver = "journald";
      volumes = [
        #"/home/${configVars.userName}/container-data/${app}/${db}:/var/lib/postgresql/data"
        "${db}-${app}:/var/lib/postgresql/data"
      ];
      environmentFiles = [config.sops.templates."${db}-env".path];
      extraOptions = [
        "--network=${app}"
        #"--network=backend"
      ];
    };
  };

  systemd.services."docker-${app}" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-${app}.service"
      "docker-volume-${app}.service"
    ];
    requires = [
      "docker-network-${app}.service"
      "docker-volume-${app}.service"
    ];
    partOf = [
      "docker-${app}-root.target"
    ];
    unitConfig.UpheldBy = [
      "docker-${db}-${app}.service"
    ];
    wantedBy = [
      "docker-${app}-root.target"
    ];
  };

  systemd.services."docker-postgres" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-${app}.service"
      "docker-volume-${db}-${app}.service"
    ];
    requires = [
      "docker-network-${app}.service"
      "docker-volume-${db}-${app}.service"
    ];
    partOf = [
      "docker-${app}-root.target"
    ];
    wantedBy = [
      "docker-${app}-root.target"
    ];
  };

  systemd.services."docker-network-${app}" = {
    path = [pkgs.docker];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.docker}/bin/docker network rm -f ${app}";
    };
    script = ''
      docker network inspect ${app} || docker network create ${app}
    '';
    partOf = ["docker-${app}-root.target"];
    wantedBy = ["docker-${app}-root.target"];
  };

  systemd.services."docker-volume-${app}" = {
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

  systemd.services."docker-volume-${db}-${app}" = {
    path = [pkgs.docker];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect ${db}-${app} || docker volume create ${db}-${app}
    '';
    partOf = ["docker-${app}-root.target"];
    wantedBy = ["docker-${app}-root.target"];
  };

  systemd.targets."docker-${app}-root" = {
    unitConfig = {
      Description = "root target for docker-${app}";
    };
    wantedBy = ["multi-user.target"];
  };

}