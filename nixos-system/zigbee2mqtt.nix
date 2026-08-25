{
  config,
  lib,
  pkgs,
  configVars,
  nixServiceRecoveryScript,
  ...
}:

# requires services.mosquitto (home-assistant.nix) and an SMLIGHT SLZB-06MG24U
# on the LAN in SLZB-OS "Zigbee2MQTT (TCP)" mode at configVars.devices.slzb06.ipv4
#
# device naming convention, follow for everything added to this network:
#   <Area>/<Fixture> <Element>
#   Area     room, Title Case. `/` is a zigbee2mqtt topic separator, so this
#            becomes an MQTT topic segment and a frontend folder
#   Fixture  the physical object, vendor-neutral - this network mixes Hue and non-Hue
#   Element  only for fixtures with more than one radio; physical position
#            (L/R) where one exists, otherwise 1/2/3
# A group is the same path without an element, so `Basement/Triple Lamp` and
# `Basement/Triple Lamp Short` slugify to distinct entity ids. Renaming changes
# the entity id, so update referencing automations in the same commit.

let

  app = "zigbee2mqtt";
  dataDir = "/var/lib/${app}";

  # default fade for on/off, brightness, colour and colour temp, in seconds.
  # set as a device/group *option* rather than per-command: zigbee-herdsman's
  # getTransition falls back to options.transition when a message carries none,
  # so this covers dashboard taps, scene recalls and automations alike. without
  # it every change snaps instantly, where the hue bridge always faded.
  transitionSecs = 1.0;

  # one zigbee multicast group per physical fixture, members are friendly names
  # from settings.devices below. zigbee groups rather than home assistant light
  # groups: a group command is one unacked multicast where an HA group is N
  # unicasts each needing an ack, which matters on a weak uplink. single source
  # of truth for both the groups settings block and the reconciliation unit.
  # ids are explicit, never derived from attrset order: attrNames sorts
  # alphabetically, so deriving them means any rename that changes sort order
  # silently renumbers existing groups and orphans their members. pick the next
  # free integer for a new fixture and never reuse one.
  fixtureGroups = {
    "Dining Room/Chris Desk Backlight" = {
      id = 1;
      members = [
        "Dining Room/Chris Desk Backlight L"
        "Dining Room/Chris Desk Backlight R"
      ];
    };
    "Basement/Triple Lamp" = {
      id = 2;
      members = [
        "Basement/Triple Lamp Short"
        "Basement/Triple Lamp Medium"
        "Basement/Triple Lamp Long"
      ];
    };
  };

  groupSettings = lib.mapAttrs' (name: g:
    lib.nameValuePair (toString g.id) {
      friendly_name = name;
      transition = transitionSecs;
    }
  ) fixtureGroups;
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
      z2mNetworkKey = { }; # pinned so the network re-forms identically after dataDir loss; rotating it orphans every paired device
    };
    templates = {
      # zigbee2mqtt reads `!secret <key>` from ${dataDir}/secret.yaml, but this
      # renders to the default /run/secrets/rendered/ path and preStart installs
      # it: dataDir is an impermanence bind mount, and on the switch that first
      # creates the persisted directory the mount starts after sops-nix runs in
      # activation, shadowing anything written straight there.
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
          adapter = "ember"; # EFR32MG24 radio; zstack is for the TI CC2652 variants
        };

        advanced = {
          # highest ZLL channel, so it sits above the 2.4GHz wifi band wherever
          # unifi auto channel selection lands the APs. hue only supports ZLL
          # 11/15/20/25, which rules out the otherwise-quieter 26.
          channel = 25;
          transmit_power = 20; # zigbee2mqtt defaults to 5dBm; the EFR32MG24 is rated for 20
          network_key = "!secret network_key";
          pan_id = 64163; # plaintext: broadcast unencrypted in every beacon frame
          ext_pan_id = [ 233 201 89 145 149 147 3 240 ]; # same
          log_level = "info";
        };

        frontend = {
          enabled = true;
          host = "127.0.0.1"; # traefik is the only consumer; no need to listen on the LAN
          port = 8099; # default 8080 already taken by unifi
        };

        homeassistant.enabled = true;

        # keyed by IEEE address; preStart reasserts these from the nix store on
        # every start. a newly paired device writes itself into configuration.yaml
        # at join time and reverts to its bare IEEE name on the next restart until
        # added here, which keeps this file the source of truth rather than a seed.
        # transition is set on the members as well as the groups: scenes address
        # individual bulbs, group on/off addresses the group.
        devices = {
          "0x0017880102dc50e9" = { friendly_name = "Basement/Triple Lamp Short"; transition = transitionSecs; };
          "0x00178801028e5a54" = { friendly_name = "Basement/Triple Lamp Medium"; transition = transitionSecs; };
          "0x0017880102dc511c" = { friendly_name = "Basement/Triple Lamp Long"; transition = transitionSecs; };
          "0x001788010c6b174f" = { friendly_name = "Dining Room/Chris Desk Backlight L"; transition = transitionSecs; };
          "0x001788010c625697" = { friendly_name = "Dining Room/Chris Desk Backlight R"; transition = transitionSecs; };
        };

        # only the groups themselves are declarable - zigbee2mqtt 2.x dropped
        # groups.<id>.devices and moved membership to runtime state, reconciled
        # by the zigbee2mqtt-groups unit below
        groups = groupSettings;

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

  # reconciles group membership to fixtureGroups, which configuration.yaml can no
  # longer express. per declared device: strip from all groups, then add to the
  # one nix names - idempotent, and corrects drift from frontend edits. gap: a
  # device dropped from fixtureGroups entirely is never visited and keeps its old
  # membership, so clear those in the frontend.
  systemd.services."${app}-groups" = {
    description = "Reconcile ${app} group membership from nix";
    after = [ "${app}.service" ];
    requires = [ "${app}.service" ];
    partOf = [ "${app}.service" ]; # re-run whenever zigbee2mqtt restarts
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ mosquitto jq ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail

      P="$(cat ${config.sops.secrets.mqttZ2mPasswd.path})"
      MQ=(-h localhost -u ${app} -P "$P")

      # zigbee2mqtt runs well before it has connected to the broker and built its
      # group table, so wait for the bridge to report online rather than race it
      for _ in $(seq 1 60); do
        state="$(mosquitto_sub "''${MQ[@]}" -t ${app}/bridge/state -C 1 -W 3 2>/dev/null | jq -r .state 2>/dev/null || true)"
        [ "$state" = "online" ] && break
        sleep 2
      done
      if [ "''${state:-}" != "online" ]; then
        echo "zigbee2mqtt did not come online within 120s; not reconciling groups" >&2
        exit 1
      fi

      pub() {
        mosquitto_pub "''${MQ[@]}" -t "${app}/bridge/request/group/members/$1" -m "$2"
        sleep 1
      }

      ${lib.concatStringsSep "\n" (lib.flatten (lib.mapAttrsToList (group: g:
        map (m: ''
          pub remove_all ${lib.escapeShellArg (builtins.toJSON { device = m; })}
          pub add ${lib.escapeShellArg (builtins.toJSON { inherit group; device = m; })}
        '') g.members
      ) fixtureGroups))}

      echo "group membership reconciled"
    '';
  };

  systemd.services.${app} = {
    after = [ "mosquitto.service" ];
    wants = [ "mosquitto.service" ];
    # install rather than cp so it can replace the existing 0400 file, which the
    # owner cannot otherwise open for writing
    preStart = lib.mkAfter ''
      install -m 0400 ${config.sops.templates."${app}-secrets".path} ${dataDir}/secret.yaml
    '';
  };

}
