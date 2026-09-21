{
  config,
  lib,
  pkgs,
  configVars,
  nixServiceRecoveryScript,
  ...
}:

# replaces oci-unifi.nix. the native module runs unifi's *embedded* mongod
# (spawned by ace.jar from ${mongodbPackage}/bin, localhost, no auth), so the
# separate mongo container, its init script and all five unifiMongo* sops
# secrets are gone. state is fixed at /var/lib/unifi - services.unifi.dataDir
# was removed upstream.
#
# cutover checklist, all four steps in one commit (not yet applied):
#   1. hosts/aspen/configuration.nix - swap the oci-unifi.nix import for this
#   2. hosts/aspen/impermanence.nix  - persist /var/lib/unifi as unifi:unifi 0700
#   3. vars/default.nix              - comment out ociServices.unifi, frees 172.21.3.0/25
#   4. DEVIATIONS.md                 - add the pkgs.unstable.unifi row
# then, and only after the restore is verified and aspen has survived a reboot:
#   5. drop unifiMongoRootUser/RootPasswd/User/Passwd/Db from secrets.yaml
#   6. docker volume rm unifi unifi-mongodb-db unifi-mongodb-configdb
#
# migration itself is a native .unf backup/restore, not a data copy:
#   - download a full backup (settings + statistics) from the 9.0.114 web ui first
#   - stop docker-unifi-root.target, leave its three volumes intact as rollback
#   - rebuild, then restore the .unf through the setup wizard
#   - devices keep informing to 192.168.1.2:8080, so no re-adoption
#   - afterwards check /var/lib/unifi/data/system.properties for db.mongo.uri /
#     statdb.mongo.uri / db.mongo.local=false carried over from the external-mongo
#     install; strip them if present, they point at a container that no longer exists

let

  app = "unifi";
  stateDir = "/var/lib/${app}";
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
      # mongodbPackage left at the module default (mongodb-7_0), same 7.0 major
      # the mongo:7.0 container ran
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
