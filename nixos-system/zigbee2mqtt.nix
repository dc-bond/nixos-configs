{
  config,
  lib,
  pkgs,
  configVars,
  nixServiceRecoveryScript,
  ...
}:

# Requires:
#   - services.mosquitto (provided by home-assistant.nix) — reached over loopback,
#     so no firewall rule is needed: nixos-fw accepts `-i lo` unconditionally.
#   - an SMLIGHT SLZB-06MG24U POE Zigbee coordinator on the LAN, running SLZB-OS
#     in "Zigbee2MQTT (TCP)" mode, reachable at configVars.devices.slzb06.ipv4:6638
#   - sops secrets `mqttZ2mPasswd` (also seeds the mosquitto user in
#     home-assistant.nix) and `z2mNetworkKey`
#
# Adapter: the SLZB-06MG24U carries a Silicon Labs EFR32MG24 radio, so the
# serial adapter is `ember` (EmberZNet/EZSP). `zstack` is for the TI CC2652
# variants (SLZB-06/06M/06P7) and will not drive this hardware.
#
# Channel 25 is deliberate and should not be changed casually: it is the highest
# ZLL channel, so it sits above the entire 2.4GHz WiFi band (WiFi ch11 tops out
# ~2473MHz, Zigbee ch25 centers at 2475MHz). That keeps it clear of the UniFi APs
# regardless of where auto channel selection lands them, including a future
# multi-AP WiFi 7 deployment. Philips Hue devices only support ZLL channels
# 11/15/20/25, which rules out the otherwise-quieter channel 26.
#
# Secrets: `settings` is rendered into the world-readable nix store, so anything
# sensitive goes through zigbee2mqtt's `!secret <key>` indirection, which reads
# `${dataDir}/secret.yaml` (rendered below by sops-nix). Only mqtt.user,
# mqtt.password, mqtt.server, advanced.network_key and frontend.auth_token
# support that indirection upstream — pan_id/ext_pan_id do not, so they sit here
# in plaintext. That is fine: both are transmitted unencrypted in every Zigbee
# beacon frame, so they are readable by any sniffer in RF range already. The
# network key is the value that actually matters, and it stays in sops.

let

  app = "zigbee2mqtt";
  dataDir = "/var/lib/${app}";
  recoveryPlan = {
    restoreItems = [
      dataDir
    ];
    stopServices = [ "${app}" ];
    startServices = [ "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
  };

in

{

  sops = {
    secrets = {
      mqttZ2mPasswd = { };
      # Zigbee network encryption key, pinned rather than left to zigbee2mqtt's
      # first-run random generation, so the network can be re-formed identically
      # after a total loss of dataDir without re-pairing every device. Never
      # rotate this casually: changing it forms a *new* zigbee network and
      # orphans every paired device.
      z2mNetworkKey = { };
    };
    templates = {
      # zigbee2mqtt resolves `!secret <key>` against `${dataDir}/secret.yaml`, but
      # this template is deliberately NOT rendered straight to that path. dataDir
      # is an impermanence bind mount, and sops-nix runs in activation (deps:
      # specialfs/users/groups) — on the switch that first creates the persisted
      # directory, the mount unit starts *after* activation and shadows anything
      # sops just wrote there. Render to the default /run/secrets/rendered/
      # location instead and have preStart copy it in, which is correct on both a
      # cold boot and a live switch.
      "${app}-secrets" = {
        content = ''
          mqtt_password: ${config.sops.placeholder.mqttZ2mPasswd}
          network_key: ${config.sops.placeholder.z2mNetworkKey}
        '';
        owner = config.users.users.${app}.name;
        group = config.users.users.${app}.group;
        mode = "0400";
      };
    };
  };

  environment.systemPackages = with pkgs; [ recoverScript ];

  backups.serviceHooks = {
    preHook = lib.mkAfter [ "systemctl stop ${app}.service" ];
    postHook = lib.mkAfter [ "systemctl start ${app}.service" ];
  };

  services = {

    ${app} = {
      enable = true;
      package = pkgs.unstable.${app}; # 25.11 ships 2.6.3; unstable for current ember/EFR32MG24 driver work (see DEVIATIONS.md)
      inherit dataDir;
      settings = {

        mqtt = {
          base_topic = app;
          server = "mqtt://localhost:1883";
          user = app;
          password = "!secret mqtt_password";
        };

        serial = {
          port = "tcp://${configVars.devices.slzb06.ipv4}:6638";
          adapter = "ember";
        };

        advanced = {
          channel = 25;
          network_key = "!secret network_key";
          # broadcast in the clear in every beacon frame — see header note
          pan_id = 64163;
          ext_pan_id = [ 233 201 89 145 149 147 3 240 ];
          log_level = "info";
        };

        frontend = {
          enabled = true;
          host = "127.0.0.1"; # traefik is the only consumer; no need to listen on the LAN
          port = 8099; # default 8080 already taken by unifi
        };

        homeassistant.enabled = true;

        # Device and group definitions are kept in the module's default sidecar
        # files while pairing, then lifted into this attrset once the IEEE
        # addresses are known. preStart rewrites configuration.yaml from the nix
        # store on every start, so anything inlined here is enforced, not merely
        # seeded.
        devices = "devices.yaml";
        groups = "groups.yaml";

      };
    };

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = [ "websecure" ];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
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
      services.${app} = {
        loadBalancer = {
          serversTransport = "default";
          servers = [
            {
              url = "http://127.0.0.1:8099";
            }
          ];
        };
      };
    };

  };

  systemd.services.${app} = {
    after = [ "mosquitto.service" ];
    wants = [ "mosquitto.service" ];
    # Runs as the zigbee2mqtt user after the upstream module's preStart has
    # written configuration.yaml. `install` (rather than cp) so it replaces the
    # existing 0400 file, which the owner cannot otherwise open for writing.
    preStart = lib.mkAfter ''
      install -m 0400 ${config.sops.templates."${app}-secrets".path} ${dataDir}/secret.yaml
    '';
  };

}
