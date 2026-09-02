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
#   <area>/<fixture>-<element>
# all lower case, hyphens for spaces. this is an identifier, not a display
# string: home assistant takes its display names from the dashboard, which sets
# `name` on every row, so nothing user-facing reads these.
#   area     room. `/` is a zigbee2mqtt topic separator, so this becomes an
#            MQTT topic segment and a frontend folder
#   fixture  the physical object, vendor-neutral - this network mixes Hue and non-Hue
#            qualify it by position or role where a room has, or will have,
#            more than one fixture - `sink-downlight`, `chris-desk-backlight`.
#            a bare noun like `ceiling` is only unambiguous while the room
#            has exactly one light
#   element  only for fixtures with more than one radio; physical position
#            (l/r) where one exists, otherwise 1/2/3
# A group is the same path without an element, so `basement/triple-lamp` and
# `basement/triple-lamp-short` slugify to distinct entity ids. Devices whose
# location is not chosen yet sit under `unassigned/`.
#
# home assistant slugifies `/`, `-` and space alike to `_`, so the entity id is
# the same whatever separators the name uses: `master-bathroom/ceiling` and
# `Master Bathroom/Ceiling` both give light.master_bathroom_ceiling. renaming
# between the two styles therefore does NOT move an entity - see below.
#
# renaming a device does NOT fix its home assistant entity id. discovery is
# retained and keyed by ieee, but only the payload's object_id carries the
# friendly name, and home assistant pins an entity id at first discovery and
# never rewrites it. to rename a fixture:
#   1. change friendly_name here
#   2. nixos-rebuild switch - z2m restarts and rewrites the retained discovery
#   3. THEN delete the device in home assistant (settings > devices > mqtt).
#      this also clears the retained discovery topics, so nothing will recreate
#      the entity on its own
#   4. systemctl restart zigbee2mqtt - republishes discovery under the new name,
#      which a running home assistant picks up live. restarting home assistant
#      instead does nothing: there is no retained payload left for it to replay
# deleting before step 2 races the stale payload and re-pins the old id. the
# `effect` and `linkquality` entities are a separate and harmless case: home
# assistant disables them by default, and a disabled entity always takes a bare
# ieee id no matter what the payload says. ignore those two rather than chasing
# them - every other entity is what scenes and automations reference.
#
# adopting a device - stop home assistant FIRST, the ordering is the point:
#   1. systemctl stop home-assistant
#   2. permit join in the frontend, then power-cycle the device to pair it
#   3. note the IEEE from the join log, add it to `devices` below with a
#      convention name, and to `fixtureGroups` if it joins a multi-radio fixture
#   4. nixos-rebuild switch (restarts home assistant)
# if home assistant is running at step 2 the device lands as
# light.0x0017880102dc50e9 forever and needs the rename procedure above.
# stopped, it first sees the device already named and derives the right id.
#
# ex-hue devices need a Touchlink or vendor power-cycle reset before they will
# join. See nixos-configs-private/hue-backup/hue-devices-reference.nix.

let

  app = "zigbee2mqtt";
  dataDir = "/var/lib/${app}";

  # default fade for on/off, brightness, colour and colour temp, in seconds.
  # set as a device/group *option* rather than per-command: zigbee-herdsman's
  # getTransition falls back to options.transition when a message carries none,
  # so this covers dashboard taps, scene recalls and automations alike. without
  # it every change snaps instantly.
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
    "dining-room/chris-desk-backlight" = {
      id = 1;
      members = [
        "dining-room/chris-desk-backlight-l"
        "dining-room/chris-desk-backlight-r"
      ];
    };
    "basement/triple-lamp" = {
      id = 2;
      members = [
        "basement/triple-lamp-short"
        "basement/triple-lamp-medium"
        "basement/triple-lamp-long"
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
          "0x0017880102dc50e9" = { friendly_name = "basement/triple-lamp-short"; transition = transitionSecs; };
          "0x00178801028e5a54" = { friendly_name = "basement/triple-lamp-medium"; transition = transitionSecs; };
          "0x0017880102dc511c" = { friendly_name = "basement/triple-lamp-long"; transition = transitionSecs; };
          "0x001788010c6b174f" = { friendly_name = "dining-room/chris-desk-backlight-l"; transition = transitionSecs; };
          "0x001788010c625697" = { friendly_name = "dining-room/chris-desk-backlight-r"; transition = transitionSecs; };
          "0x0017880103d6552f" = { friendly_name = "master-bathroom/ceiling"; transition = transitionSecs; }; # LCT016, not an LCT014 despite the shared z2m model
          "0x0017880104e5920d" = { friendly_name = "master-bathroom/dimmer"; }; # switch, transition is a light option
          "0x001788010ce32eda" = { friendly_name = "kitchen/sink-downlight"; transition = transitionSecs; }; # LCA007, full colour: xy plus 153-500 mired (2000-6535K)

          # the RWL022s are gen 2 to the bathroom's gen 1 RWL020, but z2m maps both
          # onto the same four-button action vocabulary, so their automations are
          # identical in shape. They also emit recall_0/recall_1 from the hue
          # button, which nothing consumes.
          # Which physical unit each ieee is was confirmed on 2026-09-02 by pressing
          # each dimmer and watching its action topic: the kitchen unit was the one
          # formerly labelled RWL022 3, the basement unit RWL022 1.
          "0x001788010d2905f0" = { friendly_name = "basement/dimmer"; }; # switch, transition is a light option
          "0x001788010e29213d" = { friendly_name = "kitchen/dimmer"; }; # switch, transition is a light option

          # pending fixtures, placeholder names until locations are chosen. renaming
          # one needs the ha device deleted after the rebuild, see the header.
          # the lightstrip is white AND colour ambiance despite the bare model name
          # - xy, hs and 150-500 mired - so it can carry the full five scene roles.
          "0x001788010c59b68b" = { friendly_name = "unassigned/lightstrip-lcl001"; transition = transitionSecs; };
          # these two really are brightness-only: no color_xy and no color_temp
          # either, so their scene roles can vary brightness and nothing else.
          # destined for the 3rd floor ceiling and the closet; which ieee is which
          # is not known - toggle one and watch which bulb responds before assigning
          "0x001788010d757ff2" = { friendly_name = "unassigned/white-bulb-lwa025-1"; transition = transitionSecs; };
          "0x001788010d757c69" = { friendly_name = "unassigned/white-bulb-lwa025-2"; transition = transitionSecs; };
          "0x001788010d2ba2cc" = { friendly_name = "unassigned/dimmer-rwl022-2"; };
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
