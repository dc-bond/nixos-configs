{
  config,
  lib,
  pkgs,
  configVars,
  nixServiceRecoveryScript,
  ...
}:

# native unifi controller, replaces the retired oci-unifi.nix. the module runs
# unifi's *embedded* mongod (ace.jar spawns it from ${mongodbPackage}/bin on
# localhost, no auth), so the second container, its init script and all five
# unifiMongo* sops secrets are gone. state is fixed at /var/lib/unifi -
# services.unifi.dataDir was removed upstream.
#
# migrated by a native .unf backup/restore rather than a data copy. devices
# inform to the host ip:8080 exactly as they did through docker's published
# port, so nothing needed re-adopting.
#
# outstanding until the restore is verified and aspen has survived a reboot:
#   - check /var/lib/unifi/data/system.properties for db.mongo.uri /
#     statdb.mongo.uri / db.mongo.local=false carried over from the
#     external-mongo install; strip them if present, they point at a container
#     that no longer exists
#   - drop unifiMongoRootUser/RootPasswd/User/Passwd/Db from secrets.yaml
#   - docker volume rm unifi unifi-mongodb-db unifi-mongodb-configdb (rollback
#     until then: git revert the migration, rebuild, start docker-unifi-root.target)

let

  app = "unifi";
  stateDir = "/var/lib/${app}";
  # mongodb is SSPL so hydra builds none of it: pkgs.mongodb-7_0, the module
  # default, has no binary substitute on any platform and compiles from source
  # for hours, wanting ~15G at the mongod link. mongodb-ce is the same server
  # from upstream's prebuilt tarball - fetchurl + autoPatchelfHook, nothing
  # compiled - and installs the mongod unifi actually execs.
  #
  # version is pinned rather than left at mongodb-ce's own default because
  # unifi 10.6.106's deb declares mongodb-org-server (>= 3.6.0), (<< 8.1.0):
  # 8.0 is the ceiling and the 8.2 mongodb-ce ships sits above it. 8.0 over the
  # 7.0 the old container ran because the .unf restore builds the db from
  # scratch, so the major is free to choose now and an in-place upgrade of an
  # embedded mongod later. 7.0 eols 2027-08, 8.0 2029-10.
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
    # fail-fast if the stop fails so borg doesn't cold-copy a live-writing mongod
    preHook = lib.mkAfter [ "systemctl stop ${app}.service || exit 1" ];
    postHook = lib.mkAfter [ "systemctl start ${app}.service" ];
  };

  # lan only, matching the ip-scoped publish set the docker module used. not
  # services.unifi.openFirewall, which would also open these on the docker
  # bridges. tailscale0 is already in firewall.trustedInterfaces (tailscale.nix).
  # 8443 (web ui) stays closed - traefik reaches it on loopback.
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
      # 25.11 ships 9.5.21, flagged knownVulnerabilities for CVE-2026-22557
      # (CVSSv3.1 10.0) - fixed only in 9.0.118 and >=10.1.89, and no patched 9.x
      # exists in nixpkgs. see DEVIATIONS.md
      unifiPackage = pkgs.unstable.unifi;
      # required: unifi 10.x wants jdk25 via passthru.jrePackage, which the 25.11
      # module doesn't read - it defaults to jdk17_headless and the controller
      # won't start. jdk25_headless is in 25.11, so this is not a second
      # cross-channel pull
      jrePackage = pkgs.jdk25_headless;
      # prebuilt 8.0, the newest major unifi's deb allows - see the let block
      mongodbPackage = mongodbPrebuilt;
      initialJavaHeapSize = 1024; # was MEM_STARTUP
      maximumJavaHeapSize = 2048; # was MEM_LIMIT=1024; 10.x is heavier, jvm sat at ~876M on 9.0
    };

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

    traefik.dynamicConfigOptions.http = {
      middlewares.unifi-headers.headers.customRequestHeaders.Authorization = "";
      serversTransports.unifi-insecure = {
        insecureSkipVerify = true; # required for unifi's self-signed cert
        forwardingTimeouts = {
          dialTimeout = "5s"; # max time to establish connection (down from 30s default)
          responseHeaderTimeout = "10s"; # max time to read response headers - triggers maintenance page faster
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
          serversTransport = "unifi-insecure"; # uses self-signed cert, needs insecureSkipVerify
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
