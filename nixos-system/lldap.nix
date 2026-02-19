{
  pkgs,
  lib,
  config,
  configVars,
  nixServiceRecoveryScript,
  ...
}: 

let

  app = "lldap";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/private/${app}"
      "/var/backup/postgresql/${app}.sql.gz"
    ];
    db = {
      type = "postgresql";
      user = "${app}";
      name = "${app}";
      dump = "/var/backup/postgresql/${app}.sql.gz";
    };
    stopServices = [ "${app}" ];
    startServices = [ "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
    dbType = recoveryPlan.db.type;
  };
  
in

{

  sops.secrets = {
    lldapJwtSecret = {};
    lldapLdapUserPasswd = {};
  };

  environment.systemPackages = with pkgs; [ recoverScript ];
  
  systemd.services."${app}" = {
    requires = [ "postgresql.target" ];
    after = [ "postgresql.target" ];
    serviceConfig = { # shit needed because broken settings for passwords and env permissions
      LoadCredential = [
        "jwt_secret:${config.sops.secrets.lldapJwtSecret.path}"
        "ldap_user_pass:${config.sops.secrets.lldapLdapUserPasswd.path}"
      ];
    };
  };

  backups.serviceHooks = {
    preHook = lib.mkAfter [
      "systemctl stop ${app}.service"
      "sleep 2"
      "systemctl start postgresqlBackup-${app}.service"
    ];
    postHook = lib.mkAfter [
      "systemctl start ${app}.service"
    ];
  };

  services = {

    ${app} = {
      enable = true;
      settings = {
        ldap_user_email = "${configVars.users.chris.email}";
        ldap_user_dn = "admin";
        #ldap_user_pass_file = config.sops.secrets.lldapLdapUserPasswd.path; # shit broken in 25.11
        force_ldap_user_pass_reset = "always";
        #jwt_secret_file = config.sops.secrets.lldapJwtSecret.path; # shit broken in 25.11
        ldap_port = 3890;
        ldap_base_dn = "dc=${configVars.domain1Short},dc=com";
        http_url = "https://${app}.${configVars.domain1}";
        http_port = 17170;
        http_host = "127.0.0.1";
        database_url = "postgres:///${app}";
      };
      silenceForceUserPassResetWarning = true;
      environment = {
        LLDAP_JWT_SECRET_FILE = "%d/jwt_secret";
        LLDAP_LDAP_USER_PASS_FILE = "%d/ldap_user_pass";
      };
    };

    postgresql = {
      ensureDatabases = [ "${app}" ];
      ensureUsers = [
        {
          name = "${app}";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    postgresqlBackup.databases = [ "${app}" ];

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain1}`)";
        service = "${app}";
        middlewares = [
          #"authelia-dcbond" # disabled to break circular dependency - LLDAP needs Authelia, Authelia needs LLDAP
          "secure-headers"
          "trusted-allow" # IP allowlist - restricts access to LAN + Tailscale only
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
            url = "http://127.0.0.1:17170";
          }
          ];
        };
      };
    };

    # Authelia access control rules commented out - circular dependency
    # Re-enable after both LLDAP and Authelia are running
    #authelia.instances."${configVars.domain1Short}".settings.access_control.rules = [
    #  {
    #    domain = [ "${app}.${configVars.domain1}" ];
    #    subject = [ # only allow the following users to access lldap and only require one factor
    #      "user:admin"
    #    ];
    #    policy = "one_factor";
    #  }
    #];

  };

}