{ 
  config,
  lib,
  pkgs, 
  configVars,
  dockerServiceRecoveryScript,
  ... 
}: 

let

  app = "pihole-test";
  app2 = "unbound-test";
  
  customDnsEntries = [
    "${configVars.hosts.aspen.networking.ipv4} aspen"
    "${configVars.hosts.juniper.networking.tailscaleIp} juniper-tailscale"
  ];
  
  customCnameEntries = [
    "actual.${configVars.domain2},aspen"
    "bond-ledger.${configVars.domain2},aspen"
    "calibre-web.${configVars.domain2},aspen"
    "chris-workouts.${configVars.domain2},aspen"
    "danielle-workouts.${configVars.domain2},aspen"
    "finplanner.${configVars.domain2},aspen"
    "frigate.${configVars.domain2},aspen"
    "grafana.${configVars.domain2},aspen"
    "home-assistant.${configVars.domain2},aspen"
    "jellyfin.${configVars.domain2},aspen"
    "jellyseerr.${configVars.domain2},aspen"
    "librechat.${configVars.domain2},aspen"
    "lldap.${configVars.domain1},aspen"
    "n8n.${configVars.domain2},aspen"
    "photos.${configVars.domain2},aspen"
    "pihole-test-aspen.${configVars.domain2},aspen"
    "pihole.${configVars.domain2},aspen"
    "prowlarr.${configVars.domain2},aspen"
    "radarr.${configVars.domain2},aspen"
    "recipesage.${configVars.domain2},aspen"
    "sabnzbd.${configVars.domain2},aspen"
    "search.${configVars.domain2},aspen"
    "sonarr.${configVars.domain2},aspen"
    "stirling-pdf.${configVars.domain2},aspen"
    "traefik-aspen.${configVars.domain2},aspen"
    "unifi.${configVars.domain2},aspen"
    "uptime-kuma.${configVars.domain2},aspen"
    "weekly-recipes.${configVars.domain2},aspen"
    "zwavejs.${configVars.domain2},aspen"
    "pihole-juniper.${configVars.domain2},juniper-tailscale"
    "traefik-juniper.${configVars.domain2},juniper-tailscale"
    "vaultwarden.${configVars.domain2},juniper-tailscale"
  ];
  
  piholeAdlists = [
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
    "https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt"
    "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
    "https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
    "https://v.firebog.net/hosts/Prigent-Crypto.txt"
    "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
    "https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt"
    "https://phishing.army/download/phishing_army_blocklist_extended.txt"
    "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
    "https://v.firebog.net/hosts/RPiList-Malware.txt"
    "https://v.firebog.net/hosts/RPiList-Phishing.txt"
    "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt"
    "https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/generated/hosts"
    "https://urlhaus.abuse.ch/downloads/hostfile/"
    "https://v.firebog.net/hosts/Easyprivacy.txt"
    "https://v.firebog.net/hosts/Easylist.txt"
    "https://v.firebog.net/hosts/static/w3kbl.txt"
    "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
    "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
  ];

  # init script to populate adlists database declaratively
  piholeInitScript = pkgs.writeScript "init-pihole-adlists.sh" ''
    #!/bin/bash
    
    # wait for database to be ready
    while [ ! -f /etc/pihole/gravity.db ]; do
      echo "Waiting for gravity database..."
      sleep 2
    done
    
    echo "Populating adlists from Nix configuration..."
    
    # clear existing adlists to ensure declarative state
    sqlite3 /etc/pihole/gravity.db "DELETE FROM adlist;"
    
    # add all adlists from Nix config
    ${lib.concatMapStrings (url: ''
      sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('${url}', 1, 'Managed by Nix');"
    '') piholeAdlists}
    
    echo "Added ${toString (lib.length piholeAdlists)} adlists to database"
    
    # run gravity update to apply changes
    pihole -g
    
    echo "Declarative adlists configuration complete"
  '';

  recoveryPlan = {
    restoreItems = [
      "/var/lib/docker/volumes/${app}"
      "/var/lib/docker/volumes/${app2}"
    ];
    stopServices = [ "docker-${app}-root.target" ];
    startServices = [ "docker-${app}-root.target" ];
  };
  recoverScript = dockerServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
  };

in

{
  
  environment.systemPackages = with pkgs; [ recoverScript ];

  backups.serviceHooks = {
    preHook = lib.mkAfter [ "systemctl stop docker-${app}-root.target" ];
    postHook = lib.mkAfter [ "systemctl start docker-${app}-root.target" ];
  };

  services.borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

  sops = {
    templates = {
      "${app}-env".content = ''
        TZ=America/New_York
        FTLCONF_webserver_api_password=''''
        FTLCONF_dns_upstreams=${configVars.unboundIp}#53
        FTLCONF_dns_hosts=${lib.concatStringsSep "," customDnsEntries}
        FTLCONF_dns_cnameRecords=${lib.concatStringsSep "," customCnameEntries}
        FTLCONF_dns_port=53
        FTLCONF_webserver_port=80
        VIRTUAL_HOST=${app}-${config.networking.hostName}.${configVars.domain2}
      '';
    };
  };

  virtualisation.oci-containers.containers = {

    "${app}" = {
      image = "docker.io/pihole/pihole:2025.11.1"; # https://hub.docker.com/r/pihole/pihole/tags
      #image = "docker.io/${app}/${app}:2025.11.1"; # https://hub.docker.com/r/pihole/pihole/tags
      autoStart = true;
      environmentFiles = [ config.sops.templates."${app}-env".path ];
      log-driver = "journald";
      ports = if config.networking.hostName == "juniper"
        then [ # for juniper on VPS - only listen on tailscale interface
          "${configVars.hosts."${config.networking.hostName}".networking.tailscaleIp}:53:53/tcp"
          "${configVars.hosts."${config.networking.hostName}".networking.tailscaleIp}:53:53/udp"
        ]
        else [ # for aspen on LAN - bind to all interfaces for various devices to access (from LAN, from tailscale, etc.)
          "0.0.0.0:53:53/tcp"
          "0.0.0.0:53:53/udp"
        ];
      volumes = [ 
        "${app}:/etc"
        "${piholeInitScript}:/etc/cont-init.d/99-init-adlists:ro" # put init script in location inside container so it will automatically run on container start
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.piholeIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.rule" = "Host(`${app}-${config.networking.hostName}.${configVars.domain2}`)";
        "traefik.http.routers.${app}.tls" = "true";
        "traefik.http.routers.${app}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}.middlewares" = "trusted-allow@file,secure-headers@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "80"; # port for browser interface
      };
    };

    "${app2}" = {
      image = "docker.io/mvance/unbound:1.22.0"; # https://github.com/MatthewVance/unbound-docker
      #image = "docker.io/mvance/${app2}:1.22.0"; # https://github.com/MatthewVance/unbound-docker
      autoStart = true;
      log-driver = "journald";
      volumes = [ "${app2}:/opt/unbound/etc/unbound" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.unboundIp}"
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
          "docker-volume-${app}.service"
          "docker-${app2}.service"
        ];
        requires = [
          "docker-volume-${app}.service"
          "docker-${app2}.service"
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
          docker network inspect ${app} || docker network create --subnet ${configVars.piholeSubnet} --driver bridge --scope local --attachable ${app}
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
          "docker-network-${app}.service"
          "docker-volume-${app2}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app2}.service"
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
        Description = "root target for docker-${app} and docker-${app2}";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}