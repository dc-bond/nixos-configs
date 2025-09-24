{
  pkgs,
  lib,
  config,
  configVars,
  ...
}: 

let
  app = "lldap";
  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";
  recoveryPlan = {
    serviceName = "${app}";
    localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
    cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
    restoreItems = [
      "/var/lib/private/${app}"
      "/var/backup/postgresql/${app}.sql.gz"
    ];
    db = {
      user = "${app}";
      name = "${app}";
      dump = "/var/backup/postgresql/${app}.sql.gz";
    };
    stopServices = [ "${app}" ];
    startServices = [ "${app}" ];
  };
  recoverLldapScript = pkgs.writeShellScriptBin "recoverLldap" ''
    #!/bin/bash
   
    # track errors
    set -euo pipefail

    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    # repo selection
    read -p "Use cloud repo? (y/N): " use_cloud
    if [[ "$use_cloud" =~ ^[Yy]$ ]]; then
      REPO="${recoveryPlan.cloudRestoreRepoPath}"
      echo "Using cloud repo"
    else
      REPO="${recoveryPlan.localRestoreRepoPath}"
      echo "Using local repo"
    fi

    # archive selection
    echo "Available archives at $REPO:"
    echo ""
    archives=$(${pkgs.borgbackup}/bin/borg list --short "$REPO")
    echo "$archives" | nl -w2 -s') '
    echo ""
    read -p "Enter number: " num
    ARCHIVE=$(echo "$archives" | sed -n "''${num}p")
    if [ -z "$ARCHIVE" ]; then
      echo "Invalid selection"
      exit 1
    fi
    echo "Selected: $ARCHIVE"

    # stop services
    for svc in ${lib.concatStringsSep " " recoveryPlan.stopServices}; do
      echo "Stopping $svc ..."
      systemctl stop "$svc" || true
    done

    # extract data from archive and overwrite existing data
    cd /
    echo "Extracting data from $REPO::$ARCHIVE ..."
    ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " recoveryPlan.restoreItems}
    
    # drop and recreate database
    echo "Dropping and recreating clean database ${recoveryPlan.db.name} ..."
    su - postgres -c "dropdb --if-exists ${recoveryPlan.db.name}"
    su - postgres -c "createdb -O ${recoveryPlan.db.user} ${recoveryPlan.db.name}"
    
    # restore database from dump backup
    echo "Restoring database from ${recoveryPlan.db.dump} ..."
    gunzip -c ${recoveryPlan.db.dump} | su - postgres -c "psql ${recoveryPlan.db.name}"

    # start services
    for svc in ${lib.concatStringsSep " " recoveryPlan.startServices}; do
      echo "Starting $svc ..."
      systemctl start "$svc" || true
    done

    echo "Recovery complete!
  '';
in

{

  sops = {
    secrets = {
      lldapJwtSecret = {};
      lldapLdapUserPasswd = {};
      borgCryptPasswd = {};
    };
    templates = {
      "${app}-env".content = ''
        LLDAP_JWT_SECRET=${config.sops.placeholder.lldapJwtSecret}
        LLDAP_LDAP_USER_PASS=${config.sops.placeholder.lldapLdapUserPasswd}
      '';
    };
  };

  environment.systemPackages = with pkgs; [ recoverLldapScript ];
  
  systemd.services."${app}" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  backups.serviceHooks = {
    preStop = lib.mkAfter [
      "systemctl stop ${app}.service"
      "sleep 2"
      "systemctl start postgresqlBackup-${app}.service"
    ];
    postStart = lib.mkAfter [
      "systemctl start ${app}.service"
    ];
  };

  services = {

    ${app} = {
      enable = true;
      settings = {
        ldap_user_email = "${configVars.userEmail}";
        ldap_user_dn = "admin";
        ldap_port = 3890;
        ldap_base_dn = "dc=${configVars.domain1Short},dc=com";
        http_url = "https://${app}.${configVars.domain1}";
        http_port = 17170;
        http_host = "127.0.0.1";
        database_url = "postgres:///${app}";
      };    
      environmentFile = config.sops.templates."${app}-env".path;
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

    postgresqlBackup = {
      databases = [ "${app}" ];
    };

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter [
      "/var/lib/private/${app}"
      "/var/backup/postgresql/${app}.sql.gz"
    ];

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain1}`)";
        service = "${app}";
        middlewares = [
          "authelia-dcbond"
          "secure-headers"
          "trusted-allow"
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

  };

}


    #permissions = [
    #  { path = "/var/lib/private/${app}"; owner = "${app}"; group = "${app}"; recursive = true; }
    #];
    ## ensure permissions are set correctly
    #echo "Setting permissions on restored data ..."
    #${lib.concatMapStringsSep "\n"
    #  (perm: "chown ${if perm.recursive then "-R " else ""}${perm.owner}:${perm.group} ${perm.path} || true")
    #  recoveryPlan.permissions
    #}