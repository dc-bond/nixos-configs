{
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

  virtualisation.oci-containers.containers = {
    "${app}" = {
      image = "docker.io/nitnelave/${app}:2024-01-05";
      autoStart = true;
      ports = [
        "3890:3890" # ldap port
      ]; 
      volumes = [
        "/home/${configVars.username}/${app}/${app}:/data"
      ];
      environmentFiles = [config.sops.templates."${app}-env".path];
      extraOptions = [
        "--network=backend"
      ];
      dependsOn = ["${app}-${db}"];
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
    "${app}-${db}" = {
      image = "docker.io/library/${db}:12-alpine";
      autoStart = true;
      volumes = [
        "/home/${configVars.username}/${db}:/var/lib/postgresql/data"
      ];
      environmentFiles = [config.sops.templates."${db}-env".path];
      extraOptions = [
        "--network=backend"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/${configVars.username}/${app} 0770 ${configVars.username} users -"
  ];
  
  #networking.firewall.allowedTCPPorts = [
  #  5055
  #];

}