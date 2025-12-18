{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let

  app = "pihole-test";
  app2 = "unbound-test";
  
  # Generate all hostname mappings once from configVars
  allHostMappings = let
    # NixOS hosts (LAN IPs)
    lanHostEntries = lib.mapAttrsToList (name: host: {
      ip = host.networking.ipv4;
      hostname = name;
    }) (lib.filterAttrs (_: host: host.networking.ipv4 != null) configVars.hosts);
    
    # NixOS hosts (Tailscale IPs)  
    tailscaleHostEntries = lib.mapAttrsToList (name: host: {
      ip = host.networking.tailscaleIp;
      hostname = "${name}-tailscale";
    }) (lib.filterAttrs (_: host: host.networking.tailscaleIp != null) configVars.hosts);
    
    # Mobile/other devices with Tailscale
    mobileEntries = lib.mapAttrsToList (name: device: {
      ip = device.tailscaleIp;
      hostname = name;
    }) (lib.filterAttrs (_: device: device ? tailscaleIp) configVars.devices);
    
    # Infrastructure devices
    infraEntries = lib.mapAttrsToList (name: device: {
      ip = device.ipv4;
      hostname = name;
    }) (lib.filterAttrs (_: device: device ? ipv4) configVars.devices);
    
    # Container services
    containerEntries = lib.flatten (lib.mapAttrsToList (serviceName: service:
      lib.mapAttrsToList (containerName: container: {
        ip = container.ipv4;
        hostname = containerName;
      }) service.containers
    ) configVars.containerServices);
    
  in lanHostEntries ++ tailscaleHostEntries ++ mobileEntries ++ infraEntries ++ containerEntries;
  
  # custom dnsmasq config file because all attempts at getting custom entries into the docker env file failed
  customDnsmasqConfig = pkgs.writeText "custom-dns.conf" ''
    ${lib.concatStringsSep "\n" (customDnsEntries ++ customCnameEntries)}
  '';

  customHostsConfig = let
    hostLines = map (entry: "${entry.ip} ${entry.hostname}") allHostMappings;

  in pkgs.writeText "custom-hosts.conf" ''
    127.0.0.1	localhost
    ::1	localhost ip6-localhost ip6-loopback
    fe00::0	ip6-localnet
    ff00::0	ip6-mcastprefix
    ff02::1	ip6-allnodes
    ff02::2	ip6-allrouters

    # host/device names for web UI dashboard and query log
    ${lib.concatStringsSep "\n" hostLines}
  '';

  customDnsEntries = [
    "address=/aspen.${configVars.domain1}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/aspen.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/juniper-tailscale.${configVars.domain2}/${configVars.hosts.juniper.networking.tailscaleIp}"
  ]; 
  
  customCnameEntries = [
    "cname=lldap.${configVars.domain1},aspen.${configVars.domain1}"
    "cname=actual.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=bond-ledger.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=calibre-web.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=chris-workouts.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=danielle-workouts.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=finplanner.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=frigate.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=grafana.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=home-assistant.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=jellyfin.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=jellyseerr.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=librechat.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=n8n.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=photos.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=pihole-test-aspen.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=pihole-aspen.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=pihole.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=prowlarr.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=radarr.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=recipesage.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=sabnzbd.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=search.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=sonarr.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=stirling-pdf.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=traefik-aspen.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=unifi.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=uptime-kuma.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=weekly-recipes.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=zwavejs.${configVars.domain2},aspen.${configVars.domain2}"
    "cname=pihole-juniper.${configVars.domain2},juniper-tailscale.${configVars.domain2}"
    "cname=traefik-juniper.${configVars.domain2},juniper-tailscale.${configVars.domain2}"
    "cname=vaultwarden.${configVars.domain2},juniper-tailscale.${configVars.domain2}"
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

  piholeAllowedDomains = [
    "assets.adobedtm.com" # verizon wireless
    "geo.ddc.paypal.com" # paypal
  ];

  # generate client mappings from configVars for human-readable log entries
  piholeClients = map (entry: {
    ip = entry.ip;
    comment = entry.hostname;
  }) allHostMappings;

  # systemd post-start script to initialize Pi-hole adlists  
  piholeInitScript = pkgs.writeShellScriptBin "pihole-init" ''
    #!/bin/bash
    
    echo "Waiting for Pi-hole container to be ready..."
    
    timeout=60
    while [ $timeout -gt 0 ]; do
      if docker exec ${app} echo "ready" &>/dev/null; then
        echo "Container is responsive"
        break
      fi
      echo "Waiting for container... ($timeout seconds left)"
      sleep 2
      timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
      echo "ERROR: Container did not become ready within 60 seconds"
      exit 1
    fi
    
    echo "Installing sqlite3 if needed..."
    docker exec ${app} sh -c 'if ! command -v sqlite3 &> /dev/null; then apk add sqlite; fi'
    
    echo "Waiting for Pi-hole database initialization..."
    timeout=120
    while [ $timeout -gt 0 ]; do
      if docker exec ${app} sqlite3 /etc/pihole/gravity.db "SELECT name FROM sqlite_master WHERE type='table' AND name='adlist';" 2>/dev/null | grep -q adlist; then
        echo "Pi-hole database is ready"
        break
      fi
      echo "Waiting for gravity database and tables... ($timeout seconds left)"
      sleep 5
      timeout=$((timeout - 5))
    done
    
    if [ $timeout -le 0 ]; then
      echo "ERROR: Pi-hole database did not initialize within 120 seconds"
      exit 1
    fi
    
    echo "Waiting for FTL to settle..."
    sleep 10 
    
    echo "Temporarily disabling Pi-hole to avoid database locks..."
    docker exec ${app} pihole disable
    sleep 2
    
    echo "Populating ADLISTS from Nix configuration..."
    
    # clear Pi-hole's auto-created default adlists to ensure declarative state
    docker exec ${app} sqlite3 /etc/pihole/gravity.db "DELETE FROM adlist;"
    
    # get current timestamp for date fields
    CURRENT_TIME=$(date +%s)
    
    # add all adlists from Nix config with proper schema
    ${lib.concatMapStrings (url: ''
    docker exec ${app} sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, date_added, date_modified, comment, date_updated, number, invalid_domains, status) VALUES ('${url}', 1, $CURRENT_TIME, $CURRENT_TIME, 'Managed by Nix', 0, 0, 0, 0);"
    '') piholeAdlists}
    
    echo "Added ${toString (lib.length piholeAdlists)} adlists to database"
    
    echo "Running gravity update to download and process lists..."
    docker exec ${app} pihole -g
    
    echo "Waiting for database to become fully writable..."
    sleep 10
    
    echo "Populating ALLOWLISTS from Nix configuration..."
    
    # clear Pi-hole's auto-created default allowlists to ensure declarative state  
    docker exec ${app} sqlite3 /etc/pihole/gravity.db "DELETE FROM domainlist;"
    
    # add all allowed domains from Nix config
    ${lib.concatMapStrings (domain: ''
    docker exec ${app} sqlite3 /etc/pihole/gravity.db "INSERT INTO domainlist (domain, type, enabled, date_added, date_modified, comment) VALUES ('${domain}', 0, 1, $CURRENT_TIME, $CURRENT_TIME, 'Managed by Nix');"
    '') piholeAllowedDomains}
    
    echo "Added ${toString (lib.length piholeAllowedDomains)} allowed domains to database"

    echo "Populating CLIENT MAPPINGS from Nix configuration..."
    
    # clear Pi-hole's auto-created default client mappings to ensure declarative state
    docker exec ${app} sqlite3 /etc/pihole/gravity.db "DELETE FROM client;"
    
    # add all client mappings from Nix config
    ${lib.concatMapStrings (client: ''
    docker exec ${app} sqlite3 /etc/pihole/gravity.db "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('${client.ip}', $CURRENT_TIME, $CURRENT_TIME, '${client.comment}');"
    '') piholeClients}
    
    echo "Added ${toString (lib.length piholeClients)} client mappings to database"
    
    echo "Re-enabling Pi-hole..."
    docker exec ${app} pihole enable
    
    echo "Declarative adlists, allowlist, and client configuration complete!"
  '';

in

{
  
  environment.systemPackages = with pkgs; [ piholeInitScript ];

  sops = {
    secrets.piholeWebPasswd = {};
    templates = {
      "${app}-env".content = ''
        TZ=America/New_York
        FTLCONF_webserver_api_password=${config.sops.placeholder.piholeWebPasswd}
        FTLCONF_dns_upstreams=${configVars.containerServices.${app}.containers.${app2}.ipv4}#53
        FTLCONF_dns_port=58
        FTLCONF_webserver_port=80
        FTLCONF_webserver_interface_theme=default-dark
        FTLCONF_misc_etc_dnsmasq_d=true
        FTLCONF_dns_listeningMode=all
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
          "${configVars.hosts."${config.networking.hostName}".networking.tailscaleIp}:58:58/tcp"
          "${configVars.hosts."${config.networking.hostName}".networking.tailscaleIp}:58:58/udp"
        ]
        else [ # for aspen on LAN - bind to all interfaces for various devices to access (from LAN, from tailscale, etc.)
          "0.0.0.0:58:58/tcp"
          "0.0.0.0:58:58/udp"
        ];
      volumes = [ 
        "${customDnsmasqConfig}:/etc/dnsmasq.d/99-custom-dns.conf:ro"
        "${customHostsConfig}:/etc/hosts:ro"
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}-${config.networking.hostName}.entrypoints" = "websecure";
        "traefik.http.routers.${app}-${config.networking.hostName}.rule" = "Host(`${app}-${config.networking.hostName}.${configVars.domain2}`)";
        "traefik.http.routers.${app}-${config.networking.hostName}.tls" = "true";
        "traefik.http.routers.${app}-${config.networking.hostName}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}-${config.networking.hostName}.middlewares" = "trusted-allow@file,secure-headers@file";
        "traefik.http.services.${app}-${config.networking.hostName}.loadbalancer.server.port" = "80"; # port for browser interface
      };
    };

    "${app2}" = {
      image = "docker.io/mvance/unbound:1.22.0"; # https://github.com/MatthewVance/unbound-docker
      #image = "docker.io/mvance/${app2}:1.22.0"; # https://github.com/MatthewVance/unbound-docker
      autoStart = true;
      log-driver = "journald";
      volumes = [ ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app2}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

  };

  systemd = {
    services = { 
      "docker-network-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f ${app}";
        };
        script = ''
          docker network inspect ${app} || docker network create --subnet ${configVars.containerServices.${app}.subnet} --driver bridge --scope local --attachable ${app}
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
        ];
        requires = [
          "docker-network-${app}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-${app}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
          ExecStartPost = "${piholeInitScript}/bin/pihole-init"; # run init script for adlists, allowlists, and client mappings
        };
        after = [
          "docker-${app2}.service"
        ];
        requires = [
          "docker-${app2}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
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