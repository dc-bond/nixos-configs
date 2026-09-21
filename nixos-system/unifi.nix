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
  recoveryPlan = {
    restoreItems = [ stateDir ];
    stopServices = [ "${app}" ];
    startServices = [ "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
  };

in

{

  environment.systemPackages = with pkgs; [ recoverScript ];

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
    ];
  };

  services = {

    "${app}" = {
      enable = true;
      unifiPackage = pkgs.unstable.unifi; # 25.11's 9.5.21 is flagged knownVulnerabilities, see DEVIATIONS.md
      jrePackage = pkgs.jdk25_headless; # unifi 10.x needs jdk25; the 25.11 module ignores passthru.jrePackage and defaults to jdk17
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
