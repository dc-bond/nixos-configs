{
  config,
  lib,
  configLib,
  configVars,
  pkgs,
  inputs,
  nixServiceRecoveryScript,
  ...
}: 

let

  app = "home-assistant";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/hass"
      "/var/lib/mosquitto"
      "/var/backup/postgresql/hass.sql.gz"
    ];
    db = {
      type = "postgresql";
      user = "hass";
      name = "hass";
      dump = "/var/backup/postgresql/hass.sql.gz";
    };
    stopServices = [ "${app}" "mosquitto" ];
    startServices = [ "mosquitto" "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
    dbType = recoveryPlan.db.type;
  };

  # Removes the built-in Energy panel from the sidebar. The lovelace Energy view
  # renders the same content through energy-* cards and adds live demand on top,
  # so the panel is a duplicate entry - but it cannot be switched off from
  # configuration.yaml. energy/async_setup calls
  # frontend.async_register_built_in_panel unconditionally, in the same call
  # that sets up the websocket api those cards and EnergyCostSensor depend on,
  # and the component's CONFIG_SCHEMA is cv.empty_config_schema. Dropping
  # `energy` from the config below would take all three with it.
  #
  # A custom integration is the supported hook. `dependencies` guarantees the
  # ordering: setup.py awaits every dependency future before running a
  # component's own async_setup, so energy is fully registered by the time this
  # fires. async_remove_panel then pops the one entry out of
  # hass.data[DATA_PANELS] and fires EVENT_PANELS_UPDATED - nothing else is
  # touched, and the api, cost sensors and cards all keep working.
  #
  # This must go through services.home-assistant.customComponents rather than a
  # tmpfiles symlink: the module's pre-start script deletes every symlink under
  # custom_components/ that points into /nix/store, then recreates only the ones
  # from that option, so a hand-planted symlink is removed on the next restart.
  #
  # The `version` key in the manifest is mandatory - HA's loader blocks custom
  # integrations without one outright. Expect one "custom integration ... has not
  # been tested" warning per startup; that is the loader announcing any custom
  # integration, not a fault in this one.
  energyPanelHideSrc = pkgs.runCommand "energy-panel-hide-src" { } ''
    mkdir -p $out
    cp ${pkgs.writeText "manifest.json" (builtins.toJSON {
      domain = "energy_panel_hide";
      name = "Energy Panel Hide";
      version = "1.0.0";
      documentation = "https://github.com/dc-bond/nixos-configs";
      dependencies = [ "energy" ];
      codeowners = [ ];
      iot_class = "calculated";
    })} $out/manifest.json
    cp ${pkgs.writeText "__init__.py" ''
      """Remove the built-in Energy panel from the sidebar.

      The lovelace Energy view renders the panel's content through energy-*
      cards, so the sidebar entry is a duplicate. The energy integration
      registers it unconditionally, so removing it afterwards is the only way to
      drop the panel while keeping the websocket api that those cards and
      EnergyCostSensor need.
      """

      from homeassistant.components import frontend
      from homeassistant.core import HomeAssistant
      from homeassistant.helpers import config_validation as cv
      from homeassistant.helpers.typing import ConfigType

      DOMAIN = "energy_panel_hide"

      CONFIG_SCHEMA = cv.empty_config_schema(DOMAIN)


      async def async_setup(hass: HomeAssistant, config: ConfigType) -> bool:
          """Drop the energy panel once the energy integration has registered it."""
          frontend.async_remove_panel(hass, "energy")
          return True
    ''} $out/__init__.py
  '';

  energyPanelHide = pkgs.buildHomeAssistantComponent {
    owner = "dc-bond";
    domain = "energy_panel_hide";
    version = "1.0.0";
    src = energyPanelHideSrc;
  };

in

{

  imports = [
    inputs.private.nixosModules.home-assistant-automations
    inputs.private.nixosModules.home-assistant-lovelace
    inputs.private.nixosModules.home-assistant-scenes
  ];

  sops = {
    secrets = {
      mqttHassPasswd = {};
      mqttZ2mPasswd = {}; # mosquitto user for zigbee2mqtt (zigbee2mqtt.nix)
      chrisEmailPasswd = {};
    };
    templates = {
      "hass-secrets" = {
        content = ''
          notifySenderEmail: ${configVars.users.chris.email}
          notifySenderAlias: ${configVars.users.chris.email}
          notifyDefaultRecipient: ${configVars.users.chris.email}
          notifyEmailServer: ${configVars.mailservers.namecheap.smtpHost}
          notifyEmailUsername: ${configVars.users.chris.email}
          notifyEmailPasswd: ${config.sops.placeholder.chrisEmailPasswd}
          notifyEmailPort: ${toString configVars.mailservers.namecheap.smtpPort}
        '';
        path = "/var/lib/hass/secrets.yaml";
        owner = "${config.users.users.hass.name}";
        group = "${config.users.users.hass.group}";
        mode = "0440";
      };
    };
  };

  environment.systemPackages = with pkgs; [ recoverScript ];


  systemd.services."${app}" = {
    requires = [ "postgresql.target" ];
    after = [ "postgresql.target" ];
  };
  
  backups.serviceHooks = {
    preHook = lib.mkAfter [
      "systemctl stop ${app}.service"
      "systemctl stop mosquitto.service"
      "sleep 2"
      # fail-fast on dump errors so silent DB backup failures surface via the existing
      # OnFailure email/ntfy path instead of borg archiving a stale .prev.sql.gz
      "systemctl start --wait postgresqlBackup-hass.service || exit 1"
      "test -s /var/backup/postgresql/hass.sql.gz || exit 1"
    ];
    postHook = lib.mkAfter [
      "systemctl start mosquitto.service"
      "systemctl start ${app}.service"
    ];
  };

  services = {

    ${app} = {
      enable = true;
      package = (pkgs.home-assistant.override {
        extraPackages = py: with py; [ psycopg2 ];
        }).overrideAttrs (oldAttrs: {
          doInstallCheck = false;
        });
      customComponents = [ energyPanelHide ];
      extraComponents = [
        "default_config"
        "mqtt"
        "zwave_js"
        "mobile_app"
        "notify"
        "smtp"
        "airgradient" # indoor/outdoor air monitors (configVars.devices.{indoor,outdoor}AirMonitor); local polling, UI config flow
        "rainforest_eagle" # eagle 3 smart meter gateway (configVars.devices.eagle3); local api, UI config flow - creds are eagle3CloudId/eagle3InstallCode in secrets.yaml
      ];
      config = {
        http = {
          server_port = 8123;
          use_x_forwarded_for = true;
          trusted_proxies = [
            "127.0.0.1"
          ];
        };
        recorder.db_url = "postgresql://@/hass";

        # The eagle's summation sensor is the meter's cumulative register. It
        # reads ~152 MWh while the utility bills off a five-digit display: the
        # 2026-08-26 statement read 51,790.24 against 152,207.945 in HA nine days
        # later, a clean 100,000 offset plus 418 kWh of real use. So the physical
        # register has wrapped once and the eagle keeps counting past it - the
        # sensor itself is monotonic and does not wrap. Either way ~50 MWh of it
        # predates us (moved in 2026-08-06, ~43 kWh/day), so it is useless as a
        # displayed number. utility_meter derives per-cycle totals from it.
        # periodically_resetting is false because the register is monotonic and
        # never rolls back to zero.
        utility_meter = {
          electricity_daily = {
            source = "sensor.eagle_200_total_energy_delivered";
            cycle = "daily";
            periodically_resetting = false;
          };
          electricity_monthly = {
            source = "sensor.eagle_200_total_energy_delivered";
            cycle = "monthly";
            periodically_resetting = false;
          };
          # Cycles the cost sensor the energy integration creates once a price is
          # set on the grid consumption source. That sensor does not exist until
          # then, so this meter reads unavailable and the dashboard's "Cost /
          # Today" row reads unknown - both light up on their own when the price
          # lands, with no config change. Same shape as the energy meters above:
          # the cost sensor is TOTAL and accumulates, so it never resets to zero.
          electricity_cost_daily = {
            source = "sensor.eagle_200_total_energy_delivered_cost";
            cycle = "daily";
            periodically_resetting = false;
          };
        };

        # Rolling 24h peak/baseline over instantaneous demand. Peak is what
        # drives a demand charge; the 5th percentile approximates always-on
        # load, so a rise in it means something new is drawing continuously.
        # Baseline is a percentile rather than value_min because an extremum
        # latches onto a single sample for the whole window - the sag before
        # the 2026-09-03 outage pinned it at 0.528 kW off four samples out of
        # 1395. sampling_size must cover the window - the eagle polls every
        # 30s, so 24h is 2880 samples, and the default of 20 would only look
        # back ten minutes.
        sensor = [
          {
            platform = "statistics";
            name = "Electricity Peak Demand";
            entity_id = "sensor.eagle_200_power_demand";
            state_characteristic = "value_max";
            sampling_size = 2880;
            max_age.hours = 24;
          }
          {
            platform = "statistics";
            name = "Electricity Baseline Load";
            entity_id = "sensor.eagle_200_power_demand";
            state_characteristic = "percentile";
            percentile = 5;
            sampling_size = 2880;
            max_age.hours = 24;
          }
        ];
        # `history` is in the package via default_config in extraComponents, but
        # extraComponents only builds a component in - it does not enable it, and
        # nothing here ever set default_config. Without this key the integration
        # never loads and every history-graph / statistics-graph card renders
        # "History integration disabled" instead of a chart. Enabled on its own
        # rather than via default_config, which would also pull in cloud,
        # bluetooth, ssdp/zeroconf/usb discovery, go2rtc and ~20 more.
        # Deps (http, recorder) are both already configured above.
        history = { };
        # Same story as history: energy registers its sidebar panel inside
        # async_setup, so without this key there is no Energy item in the sidebar
        # and no way to configure grid consumption at all. Deps (websocket_api,
        # history, recorder) are all satisfied above. Its schema is
        # empty_config_schema - the sources and rates are stored in .storage and
        # set through the UI, so there is nothing to declare here.
        energy = { };
        # Loads the custom integration built in the let block above, whose only
        # job is to remove the duplicate Energy sidebar panel. See the comment
        # there for why this cannot be done from configuration.yaml directly.
        energy_panel_hide = { };
        "automation ui" = "!include automations.yaml";
        #"automation nixos" defined in private repo via inputs.private.nixosModules.home-assistant-automations, merged in with ui-generated automations
        mobile_app = "";
        notify = {
          name = "email";
          platform = "smtp";
          sender = "!secret notifySenderEmail";
          sender_name = "!secret notifySenderAlias";
          recipient = [ "!secret notifyDefaultRecipient" ];
          server = "!secret notifyEmailServer";
          port = "!secret notifyEmailPort";
          timeout = 60;
          username = "!secret notifyEmailUsername";
          password = "!secret notifyEmailPasswd";
          encryption = "starttls"; # for port 587
          #encryption = "tls"; # for port 465
        };
        rest_command = {
          ntfy_notify = {
            url = "https://ntfy.${configVars.domain2}/homelab-info";
            method = "POST";
            content_type = "text/plain";
            payload = "{{ message }}";
          };
        };
      };
    };
    
    mosquitto = {
      enable = true;
      logType = [ "error" ];
      logDest = [ "syslog" ];
      listeners = [
        {
          users.hass = {
            acl = [ "readwrite #" ];
            passwordFile = "${config.sops.secrets.mqttHassPasswd.path}";
          };
          users.zigbee2mqtt = {
            acl = [ "readwrite #" ];
            passwordFile = "${config.sops.secrets.mqttZ2mPasswd.path}";
          };
        }
      ];
    };

    postgresql = {
      ensureDatabases = [ "hass" ];
      ensureUsers = [
        {
          name = "hass";
          ensureDBOwnership = true;
        }
      ];
    };

    postgresqlBackup.databases = [ "hass" ];
    
    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;
    
    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          "maintenance-page"
          #"authelia" # ios app does not support authentication provider sittnig in front of home assistant
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
          passHostHeader = true;
          servers = [
          {
            url = "http://127.0.0.1:8123";
          }
          ];
        };
      };
    };

  };

}