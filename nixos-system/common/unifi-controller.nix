{ 
  pkgs, 
  config,
  configVars,
  lib,
  nixServiceRecoveryScript,
  ... 
}: 

let

  app = "unifi-controller";
  #borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";
  #recoveryPlan = {
  #  serviceName = "${app}";
  #  localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
  #  cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
  #  restoreItems = [
  #    "/var/lib/private/${app}"
  #    "/var/backup/postgresql/${app}.sql.gz"
  #  ];
  #  db = {
  #    type = "postgresql";
  #    user = "${app}";
  #    name = "${app}";
  #    dump = "/var/backup/postgresql/${app}.sql.gz";
  #  };
  #  stopServices = [ "${app}" ];
  #  startServices = [ "${app}" ];
  #};
  #recoverScript = nixServiceRecoveryScript {
  #  serviceName = app;
  #  recoveryPlan = recoveryPlan;
  #  dbType = recoveryPlan.db.type;
  #};
  
in

{

  #sops.secrets.borgCryptPasswd = {};
  
  #environment.systemPackages = with pkgs; [ recoverScript ];

  #systemd.services."${app}" = {
  #  requires = [ "postgresql.service" ];
  #  after = [ "postgresql.service" ];
  #};

  #backups.serviceHooks = {
  #  preHook = lib.mkAfter [
  #    "systemctl stop ${app}.service"
  #    "sleep 2"
  #    "systemctl start postgresqlBackup-${app}.service"
  #  ];
  #  postHook = lib.mkAfter [
  #    "systemctl start ${app}.service"
  #  ];
  #};

  networking.firewall = {
    allowedUDPPorts = [ 
      #1900 # required for 'make controller discoverable on L2 network' option
      #3478 # STUN port
      #5514 # remote syslog port
      10001 # AP discovery port
    ];
    allowedTCPPorts = [ 
      6789 # mobile throughput test
      8080 # device communication port
      #8443 # web admin port, not necessary to open if traefik sitting in front
      8843 # guest portal https redirect port
      8880 # guest portal http redirect port
    ];
  };

  services = {

    unifi.enable = true;

    #borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;
  
    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
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
            url = "http://127.0.0.1:8443";
          }
          ];
        };
      };
    };

  };

}