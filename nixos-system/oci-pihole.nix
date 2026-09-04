{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let

  app = "pihole";
  app2 = "unbound";
  unboundIp = configVars.ociServices.${app}.containers.${app2}.ipv4;
  
  # generate hostname mappings from configVars
  allHostMappings = let

    hostEntries = lib.flatten (lib.mapAttrsToList (name: host:
      let
        lanEntry = lib.optional (host.networking.ipv4 != null) {
          ip = host.networking.ipv4;
          hostname = "${name}-lan";
        };
        tailscaleEntry = lib.optional (host.networking.tailscaleIp != null) {
          ip = host.networking.tailscaleIp;
          hostname = "${name}-tailscale";
        };
      in lanEntry ++ tailscaleEntry
    ) configVars.hosts);

    deviceEntries = lib.flatten (lib.mapAttrsToList (name: device: 
      let
        lanEntry = lib.optional (device.ipv4 != null) {
          ip = device.ipv4;
          hostname = if (device.tailscaleIp != null) then "${name}-lan" else name;
        };
        tailscaleEntry = lib.optional (device.tailscaleIp != null) {
          ip = device.tailscaleIp;
          hostname = "${name}-tailscale";
        };
      in lanEntry ++ tailscaleEntry
    ) configVars.devices);
    
    containerEntries = lib.flatten (lib.mapAttrsToList (serviceName: service:
      lib.mapAttrsToList (containerName: container: {
        ip = container.ipv4;
        hostname = containerName;
      }) service.containers
    ) configVars.ociServices);
    
  in hostEntries ++ deviceEntries ++ containerEntries;
  
  # custom unbound forward-first config - tries recursive resolution first, falls back to Quad9 DNS-over-TLS on failure
  unboundForwardConfig = pkgs.writeText "forward-records.conf" ''
    forward-zone:
        name: "."
        forward-first: yes
        forward-tls-upstream: yes
        forward-addr: 9.9.9.9@853#dns.quad9.net
        forward-addr: 149.112.112.112@853#dns.quad9.net
  '';

  # docker-${app2}.service is Type=simple, so systemd marks it started when `docker run` forks, not
  # when unbound answers - block until it actually resolves
  waitForUnbound = pkgs.writeShellScript "wait-for-${app2}" ''
    deadline=$(( SECONDS + 120 ))
    until ${pkgs.dnsutils}/bin/dig +short +timeout=2 +tries=1 @${unboundIp} cloudflare.com >/dev/null 2>&1; do
      if [ "$SECONDS" -ge "$deadline" ]; then
        echo "unbound at ${unboundIp} not answering after 120s" >&2
        exit 1
      fi
      sleep 2
    done
    echo "unbound at ${unboundIp} is resolving"
  '';

  # gravity lives only in the container writable layer, so an empty blocklist is indistinguishable
  # from a healthy one from outside - pihole still serves dns and still reports "blocking enabled".
  # export the row counts so prometheus can tell the two apart
  gravityExporter = pkgs.writeShellScript "${app}-gravity-exporter.sh" ''
    #!/usr/bin/env bash
    set -euo pipefail

    TEXTFILE_DIR="/var/lib/prometheus/node-exporter-text-files"
    METRICS_FILE="$TEXTFILE_DIR/${app}_gravity.prom.$$"
    FINAL_FILE="$TEXTFILE_DIR/${app}_gravity.prom"

    mkdir -p "$TEXTFILE_DIR"

    query() {
      ${pkgs.docker}/bin/docker exec ${app} pihole-FTL sqlite3 /etc/pihole/gravity.db "$1" 2>/dev/null
    }

    # a failed query must not be published as zero domains - emit success=0 and leave the count
    # off entirely so the absent() alert fires instead of a false "gravity empty"
    if gravity=$(query "SELECT COUNT(*) FROM gravity;") && [ -n "$gravity" ]; then
      adlist_total=$(query "SELECT COUNT(*) FROM adlist;")
      adlist_enabled=$(query "SELECT COUNT(*) FROM adlist WHERE enabled = 1;")
      adlist_ok=$(query "SELECT COUNT(*) FROM adlist WHERE enabled = 1 AND status = 1;")
      {
        echo "# HELP pihole_gravity_domains domains in the gravity blocklist"
        echo "# TYPE pihole_gravity_domains gauge"
        echo "pihole_gravity_domains $gravity"
        echo "# HELP pihole_adlist_total configured adlists"
        echo "# TYPE pihole_adlist_total gauge"
        echo "pihole_adlist_total $adlist_total"
        echo "# HELP pihole_adlist_enabled enabled adlists"
        echo "# TYPE pihole_adlist_enabled gauge"
        echo "pihole_adlist_enabled $adlist_enabled"
        echo "# HELP pihole_adlist_ok enabled adlists whose last download succeeded"
        echo "# TYPE pihole_adlist_ok gauge"
        echo "pihole_adlist_ok $adlist_ok"
        echo "# HELP pihole_gravity_exporter_success whether the gravity db query succeeded"
        echo "# TYPE pihole_gravity_exporter_success gauge"
        echo "pihole_gravity_exporter_success 1"
      } > "$METRICS_FILE"
    else
      {
        echo "# HELP pihole_gravity_exporter_success whether the gravity db query succeeded"
        echo "# TYPE pihole_gravity_exporter_success gauge"
        echo "pihole_gravity_exporter_success 0"
      } > "$METRICS_FILE"
    fi

    # atomic move to prevent partial reads
    mv "$METRICS_FILE" "$FINAL_FILE"
  '';

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
    # wildcard records for custom 404 page - specific records below take precedence
    #"address=/.${configVars.domain1}/${configVars.hosts.aspen.networking.ipv4}"
    #"address=/.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    # aspen base hostnames
    "address=/aspen.${configVars.domain1}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/aspen.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    # juniper base hostname
    "address=/juniper-tailscale.${configVars.domain2}/${configVars.hosts.juniper.networking.tailscaleIp}"
    # aspen services - use direct A records instead of CNAMEs for better resolver compatibility
    "address=/lldap.${configVars.domain1}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/actual.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/bond-ledger.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/calibre-web.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/chris-workouts.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/danielle-workouts.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/frigate.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/home-assistant.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/jellyfin.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/jellyseerr.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/metube.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/n8n.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/photos.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/pihole-aspen.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/prowlarr.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/radarr.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/recipesage.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/sabnzbd.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/search.${configVars.domain2}/${configVars.hosts.juniper.networking.tailscaleIp}"
    "address=/sonarr.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/stirling-pdf.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/traefik-aspen.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/unifi.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/vikunja.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/wardrobe.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/zigbee2mqtt.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    "address=/zwavejs.${configVars.domain2}/${configVars.hosts.aspen.networking.ipv4}"
    # juniper services
    "address=/alertmanager.${configVars.domain2}/${configVars.hosts.juniper.networking.tailscaleIp}"
    "address=/grafana.${configVars.domain2}/${configVars.hosts.juniper.networking.tailscaleIp}"
    "address=/homepage.${configVars.domain2}/${configVars.hosts.juniper.networking.tailscaleIp}"
    "address=/ntfy.${configVars.domain2}/${configVars.hosts.juniper.networking.tailscaleIp}"
    "address=/pihole-juniper.${configVars.domain2}/${configVars.hosts.juniper.networking.tailscaleIp}"
    "address=/prometheus.${configVars.domain2}/${configVars.hosts.juniper.networking.tailscaleIp}"
    "address=/traefik-juniper.${configVars.domain2}/${configVars.hosts.juniper.networking.tailscaleIp}"
  ];

  customCnameEntries = [
    # No CNAMEs needed - using direct A records above for better compatibility
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

  piholeBlockedDomains = [
    "mask.icloud.com" # iCloud Private Relay - causes SERVFAIL from Unbound, return NXDOMAIN instead per Apple guidance
    "mask-h2.icloud.com" # iCloud Private Relay HTTP/2 variant
  ];

  # generate client mappings from configVars
  piholeClients = map (entry: {
    ip = entry.ip;
    comment = entry.hostname;
  }) allHostMappings;

  # systemd script to initialize pihole declaratively
  piholeInitScript = pkgs.writeShellScriptBin "pihole-init" ''
    #!/bin/bash
    set -euo pipefail # without this the script exits 0 even if every sqlite statement failed

    CURRENT_TIME=$(date +%s)

    # use the image's bundled sqlite3 - `apk add` would need working dns in a path that only runs when dns is suspect
    sql() { docker exec ${app} pihole-FTL sqlite3 /etc/pihole/gravity.db "$@"; }

    echo "Verifying unbound is resolving before configuring Pi-hole..."
    ${waitForUnbound}

    # pihole's healthcheck has StartPeriod=0 and Retries=3, so `unhealthy` is expected before FTL is
    # serving - poll to the deadline rather than failing on the first unhealthy reading
    echo "Waiting for Pi-hole container to be healthy..."
    deadline=$(( SECONDS + 300 ))
    while true; do
      health_status=$(docker inspect --format='{{.State.Health.Status}}' ${app} 2>/dev/null || echo unknown)
      if [ "$health_status" = "healthy" ]; then
        echo "Container is healthy, proceeding with configuration..."
        break
      fi
      if [ "$SECONDS" -ge "$deadline" ]; then
        echo "ERROR: container not healthy after 300s (last status: $health_status)"
        docker logs --tail 50 ${app}
        exit 1
      fi
      sleep 5
    done
    
    echo "Temporarily disabling Pi-hole to avoid database locks..."
    docker exec ${app} pihole disable
    sleep 5 
    
    echo "Clearing existing database entries for declarative state..."
    # gravity/antigravity reference adlist(id) without ON DELETE CASCADE, so they must be cleared
    # first; the *_by_group tables cascade. pihole -g repopulates gravity further below.
    sql "DELETE FROM gravity;"
    sql "DELETE FROM antigravity;"
    sql "DELETE FROM adlist;"
    sql "DELETE FROM domainlist;"
    sql "DELETE FROM client;"
    
    echo "Populating ADLISTS from Nix configuration..."
    ${lib.concatMapStrings (url: ''
    sql "INSERT INTO adlist (address, enabled, date_added, date_modified, comment, date_updated, number, invalid_domains, status) VALUES ('${url}', 1, $CURRENT_TIME, $CURRENT_TIME, 'Managed by Nix', 0, 0, 0, 0);"
    '') piholeAdlists}
    echo "Added ${toString (lib.length piholeAdlists)} adlists to database"
    
    echo "Populating ALLOWLISTS from Nix configuration..."
    ${lib.concatMapStrings (domain: ''
    sql "INSERT INTO domainlist (domain, type, enabled, date_added, date_modified, comment) VALUES ('${domain}', 0, 1, $CURRENT_TIME, $CURRENT_TIME, 'Managed by Nix');"
    '') piholeAllowedDomains}
    echo "Added ${toString (lib.length piholeAllowedDomains)} allowed domains to database"

    echo "Populating BLOCKLISTS from Nix configuration..."
    ${lib.concatMapStrings (domain: ''
    sql "INSERT INTO domainlist (domain, type, enabled, date_added, date_modified, comment) VALUES ('${domain}', 1, 1, $CURRENT_TIME, $CURRENT_TIME, 'Managed by Nix');"
    '') piholeBlockedDomains}
    echo "Added ${toString (lib.length piholeBlockedDomains)} blocked domains to database"

    echo "Populating CLIENT MAPPINGS from Nix configuration..."
    ${lib.concatMapStrings (client: ''
    sql "INSERT INTO client (ip, date_added, date_modified, comment) VALUES ('${client.ip}', $CURRENT_TIME, $CURRENT_TIME, '${client.comment}');"
    '') piholeClients}
    echo "Added ${toString (lib.length piholeClients)} client mappings to database"
    
    echo "Running gravity update to download and process all lists..."
    docker exec ${app} pihole -g
    
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
        FTLCONF_dns_upstreams=${configVars.ociServices.${app}.containers.${app2}.ipv4}#53
        FTLCONF_dns_port=53
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
      image = "docker.io/${app}/${app}:2025.11.1"; # https://hub.docker.com/r/pihole/pihole/tags
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
        "${customDnsmasqConfig}:/etc/dnsmasq.d/99-custom-dns.conf:ro"
        "${customHostsConfig}:/etc/hosts:ro"
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.ociServices.${app}.containers.${app}.ipv4}"
        "--dns=${configVars.ociServices.${app}.containers.${app2}.ipv4}" # use unbound directly for container's own DNS needs
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app2}" = {
      image = "docker.io/mvance/${app2}:1.22.0"; # https://github.com/MatthewVance/unbound-docker
      autoStart = true;
      log-driver = "journald";
      volumes = [ "${unboundForwardConfig}:/opt/unbound/etc/unbound/forward-records.conf:ro" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.ociServices.${app}.containers.${app2}.ipv4}"
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
          docker network inspect ${app} || docker network create --subnet ${configVars.ociServices.${app}.subnet} --driver bridge --scope local --attachable ${app}
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
          # ExecStartPost must finish before the start job completes, so every After= on this unit
          # now waits for a resolving upstream; TimeoutStartSec is mandatory because the module
          # ships TimeoutStartSec=0 and a blocking probe would otherwise hang boot indefinitely
          ExecStartPost = "${waitForUnbound}";
          TimeoutStartSec = lib.mkForce "180s"; # mkForce - module sets 0 at default priority
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
      "docker-${app}-init" = {
        description = "Pihole Declarative Configuration";
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = "${waitForUnbound}"; # re-verify immediately before touching pihole
          ExecStart = "${piholeInitScript}/bin/pihole-init";
          RemainAfterExit = true;
          TimeoutStartSec = "600s"; # 19 lists / ~1.9M domains needs headroom
          # a transient boot-time failure (upstream list down, slow start) should self-heal rather
          # than leave pihole serving an empty gravity db until the next rebuild
          Restart = "on-failure";
          RestartSec = "30s";
          ExecStartPost = "${gravityExporter}"; # publish fresh counts as soon as gravity completes
        };
        after = [ "docker-${app}.service" "docker-${app2}.service" ];
        requires = [ "docker-${app}.service" "docker-${app2}.service" ];
        wantedBy = [ "docker-${app}-root.target" ];
      };
      "${app}-gravity-exporter" = {
        description = "Export Pi-hole gravity metrics for node_exporter";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${gravityExporter}";
        };
      };
    };
    timers."${app}-gravity-exporter" = {
      description = "Pi-hole Gravity Metrics Export Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10m"; # let the boot-time gravity rebuild finish before first sample
        OnUnitActiveSec = "5m";
      };
    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for docker-${app} and docker-${app2}";
      };
      wantedBy = ["multi-user.target"];
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers."${app}-${config.networking.hostName}" = {
      entrypoints = ["websecure"];
      rule = "Host(`${app}-${config.networking.hostName}.${configVars.domain2}`)";
      service = "${app}-${config.networking.hostName}";
      middlewares = [
        "maintenance-page"
        "trusted-allow"
        "secure-headers"
        "forbidden-page"
      ];
      tls = {
        certResolver = "cloudflareDns";
        options = "tls-13@file";
      };
    };
    services."${app}-${config.networking.hostName}" = {
      loadBalancer = {
        serversTransport = "default";
        servers = [
          {
            url = "http://${configVars.ociServices.${app}.containers.${app}.ipv4}:80";
          }
        ];
      };
    };
  };

}