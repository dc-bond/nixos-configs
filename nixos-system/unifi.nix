{
  config,
  lib,
  pkgs,
  configVars,
  nixServiceRecoveryScript,
  ...
}:

# runs unifi's embedded mongod from ${mongodbPackage}/bin on localhost with no
# auth, so there is no separate database service. state is fixed at /var/lib/unifi.

let

  app = "unifi";
  stateDir = "/var/lib/${app}";
  # no mongodb in nixpkgs has a binary substitute - it is SSPL, so hydra skips
  # it and pkgs.mongodb-7_0 compiles from source for hours. mongodb-ce is the
  # same server from upstream's prebuilt tarball. pinned to 8.0 because unifi's
  # deb requires mongodb-org-server >= 3.6.0, << 8.1.0 and mongodb-ce ships 8.2.
  mongodbVersion = "8.0.32";
  mongodbPrebuilt = pkgs.mongodb-ce.overrideAttrs (_: {
    version = mongodbVersion;
    src = pkgs.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2404-${mongodbVersion}.tgz";
      hash = "sha256-tBG+F8Me8kl2ftkZdNh24AfJGv1fReFTQFfSR+ranw0=";
    };
  });
  lanInterface = configVars.hosts."${config.networking.hostName}".networking.ethernetInterface;
  syslogPort = 1514;
  # pinged every minute for the unifiDeviceUnreachable alert (monitoring-server.nix);
  # an unplugged device joins once it is back in service
  monitoredDevices = with configVars.devices; {
    "Gateway UXG Max" = unifiGateway.ipv4;
    "Switch Pro 24 400W" = unifiSwitchPro24.ipv4;
    "AP U7 Pro Wifi 7" = unifiApU7Pro.ipv4;
    "AP AC Pro Wifi 5" = unifiApAcPro.ipv4;
  };
  deviceExporter = pkgs.writeShellScript "unifi-device-exporter.sh" ''
    set -euo pipefail

    TEXTFILE_DIR="/var/lib/prometheus/node-exporter-text-files"
    METRICS_FILE="$TEXTFILE_DIR/unifi_devices.prom.$$"
    FINAL_FILE="$TEXTFILE_DIR/unifi_devices.prom"

    reachable() { ${pkgs.iputils}/bin/ping -c 3 -W 2 -q "$1" >/dev/null 2>&1 && echo 1 || echo 0; }

    {
      echo "# HELP unifi_device_reachable 1 if the unifi device answered ping from aspen"
      echo "# TYPE unifi_device_reachable gauge"
    ${lib.concatStrings (lib.mapAttrsToList (name: ip: ''
      echo "unifi_device_reachable{device=\"${name}\",ip=\"${ip}\"} $(reachable ${ip})"
    '') monitoredDevices)}
    } > "$METRICS_FILE"

    mv "$METRICS_FILE" "$FINAL_FILE"
  '';
  recoveryPlan = {
    restoreItems = [ stateDir ];
    stopServices = [ "${app}" ];
    startServices = [ "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
  };
  # one call against the classic api as a local site admin; standalone 10.6 has
  # no api keys, so it is a session login (cookie + csrf header) per call.
  # loopback, so traefik and lan re-addressing don't affect it. root-only, as
  # it reads the password secret: sudo unifi-api GET /api/s/default/stat/device
  apiUser = "claude";
  unifiApi = pkgs.writeShellApplication {
    name = "unifi-api";
    runtimeInputs = with pkgs; [ curl jq gawk coreutils ];
    excludeShellChecks = [ "SC2016" ]; # single-quoted jq and awk programs
    text = ''
      if [ $# -lt 2 ]; then
        echo "usage: unifi-api METHOD PATH [JSON]" >&2
        exit 2
      fi
      method=$1
      path=$2
      body=''${3:-}
      base=https://127.0.0.1:8443
      jar=$(mktemp)
      csrf() { awk '$6 == "csrf_token" { print $7 }' "$jar"; }
      logout() {
        curl -sk -b "$jar" -H "X-Csrf-Token: $(csrf)" -X POST "$base/api/logout" >/dev/null || true
        rm -f "$jar"
      }
      trap logout EXIT
      jq -n --arg u ${apiUser} --rawfile p ${config.sops.secrets.unifiApiPassword.path} \
        '{username: $u, password: ($p | rtrimstr("\n"))}' \
        | curl -sk --fail -c "$jar" -H 'Content-Type: application/json' -d @- "$base/api/login" >/dev/null
      args=(-sk --fail-with-body -b "$jar" -c "$jar" -X "$method" -H "X-Csrf-Token: $(csrf)")
      if [ -n "$body" ]; then
        args+=(-H 'Content-Type: application/json' -d "$body")
      fi
      curl "''${args[@]}" "$base$path"
    '';
  };

in

{

  environment.systemPackages = with pkgs; [ recoverScript unifiApi ];

  sops.secrets.unifiApiPassword = {}; # password of the ${apiUser} local site admin; root-only, the default

  backups.serviceHooks = {
    preHook = lib.mkAfter [ "systemctl stop ${app}.service || exit 1" ]; # fail fast, never cold-copy a live mongod
    postHook = lib.mkAfter [ "systemctl start ${app}.service" ];
  };

  # lan only, not services.unifi.openFirewall - that would also open these on the
  # docker bridges. tailscale0 is already a trusted interface. 8443 stays closed,
  # traefik reaches the ui on loopback.
  networking.firewall.interfaces."${lanInterface}" = {
    allowedTCPPorts = [
      8080 # device inform
      8880 # guest portal http redirect
      8843 # guest portal https redirect
      6789 # mobile throughput test
    ];
    allowedUDPPorts = [
      3478 # stun
      10001 # ap discovery
      syslogPort # device syslog, to alloy
    ];
  };

  # the controller's activity logging (rsyslogd setting) points every device at
  # this listener; they all send rfc3164. host is the device name with spaces
  # stripped. requires monitoring-client.nix, which defines loki.write.default
  environment.etc."alloy/config.alloy".text = lib.mkAfter ''

    loki.relabel "unifi" {
      forward_to = []

      rule {
        source_labels = ["__syslog_message_hostname"]
        target_label  = "host"
      }

      rule {
        source_labels = ["__syslog_message_severity"]
        target_label  = "severity"
      }
    }

    loki.source.syslog "unifi" {
      listener {
        address       = "0.0.0.0:${toString syslogPort}"
        protocol      = "udp"
        syslog_format = "rfc3164"
        labels        = { job = "unifi" }
      }
      forward_to    = [loki.write.default.receiver]
      relabel_rules = loki.relabel.unifi.rules
    }
  '';

  systemd = {
    services.unifi-device-exporter = {
      description = "Export UniFi device reachability for node_exporter";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${deviceExporter}";
      };
    };
    timers.unifi-device-exporter = {
      description = "UniFi Device Reachability Export Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = "1m";
      };
    };
  };

  services = {

    "${app}" = {
      enable = true;
      unifiPackage = pkgs.unstable.unifi; # 26.05 ships 10.2.105, older than the running 10.6.x; unifi does not support controller downgrades, see DEVIATIONS.md
      mongodbPackage = mongodbPrebuilt;
      initialJavaHeapSize = 1024;
      maximumJavaHeapSize = 2048;
    };

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

    traefik.dynamicConfigOptions.http = {
      middlewares.unifi-headers.headers.customRequestHeaders.Authorization = "";
      serversTransports.unifi-insecure = {
        insecureSkipVerify = true; # unifi serves a self-signed cert
        forwardingTimeouts = { # shorter than the 30s defaults so the maintenance page trips faster
          dialTimeout = "5s";
          responseHeaderTimeout = "10s";
        };
      };
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          "maintenance-page"
          "trusted-allow"
          "secure-headers"
          "unifi-headers"
          "forbidden-page"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      services.${app} = {
        loadBalancer = {
          serversTransport = "unifi-insecure";
          servers = [
            {
              url = "https://127.0.0.1:8443";
            }
          ];
        };
      };
    };

  };

}
