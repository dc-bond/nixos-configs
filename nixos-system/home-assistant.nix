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

  # Duquesne Light RS-Residential tariff, taken off the 2026-08-26 statement
  # (actual-read service period 2026-08-06 -> 2026-08-26, 858.125 kWh). These
  # are published tariff rates - nothing account-identifying lives here.
  #
  # The bill splits into two per-kWh groups and one fixed charge:
  #   DLC     customer charge $8.67/mo + distribution $/kWh + DSIC surcharge
  #   Supply  supply $/kWh + transmission $/kWh
  #
  # DSIC is levied on (customer charge + distribution) only, not on the whole
  # bill: 2.17% x ($8.67 + $85.96) = $2.05, which is the line exactly as printed.
  # Reading it as a whole-bill surcharge overstates it by about 2.3x.
  duquesne = rec {
    customerCharge = 8.67; # $/month, charged even at zero usage
    distribution = 0.100169; # $/kWh
    supply = 0.109568; # $/kWh
    transmission = 0.031841; # $/kWh
    dsicRate = 0.0217; # on customer charge + distribution

    # What one more kWh actually costs, and the number the cost sensors below
    # multiply by. Explicitly NOT the "Price to Compare" printed on the bill:
    # that is supply + transmission only ($0.141409) and excludes delivery, so
    # using it would understate every cost row by 42%.
    marginal = distribution * (1 + dsicRate) + supply + transmission;

    # The part of the bill that does not move with usage.
    fixed = customerCharge * (1 + dsicRate);

    # Reconciliation against the statement, as a check on the model above:
    #   fixed + 858.125 x marginal = $8.86 + $209.17 = $218.03
    # against $217.93 billed. The $0.10 gap is the printed Pennsylvania Tax
    # Adjustment (-$0.09) plus per-line rounding - 0.05%, so it is left
    # unmodelled rather than fudged. Effective all-in rate was $0.25396/kWh.
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
          # Calendar month. Kept for its long-term statistics, but no longer
          # shown on a card: the bill cycle below answers the same question
          # against the period the utility actually bills, and two rows labelled
          # "this month" reading differently is worse than either alone.
          electricity_monthly = {
            source = "sensor.eagle_200_total_energy_delivered";
            cycle = "monthly";
            periodically_resetting = false;
          };
          # The billed period. The 2026-08-26 statement read on the 26th against
          # a prior read of 2026-08-06 - that first period is short only because
          # service started on the 6th, so the cycle anchor is the 26th. offset
          # counts days after the 1st, so 25 puts the reset on the 26th.
          #
          # This is what the cost projection runs on. Projecting a bill from a
          # calendar month would forecast a period the utility never bills, and
          # would be wrong by however far the 26th sits from the 1st.
          electricity_bill_cycle = {
            source = "sensor.eagle_200_total_energy_delivered";
            cycle = "monthly";
            offset.days = 25;
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
          # Daily mean outdoor temperature, the denominator behind the degree-day
          # sensors below. The airgradient outdoor monitor changed state 691
          # times in 24h, so 1500 leaves headroom on a volatile day - same sizing
          # rule as the PM 24h means in the private repo.
          {
            platform = "statistics";
            name = "Outdoor Temperature 24h";
            unique_id = "outdoor_temperature_24h";
            entity_id = "sensor.outdoor_air_monitor_temperature";
            state_characteristic = "mean";
            precision = 1;
            sampling_size = 1500;
            max_age.hours = 24;
          }
        ];

        # Pace, previous-period and weather-normalisation sensors. All of these
        # are derived from the two utility_meter cycles and the outdoor mean
        # above - nothing here talks to the eagle directly.
        #
        # Every one returns none - rendered "unknown" - rather than a number it
        # cannot stand behind, matching the CO2/PM derived sensors in the private
        # repo. Nothing on a dashboard should read as a confident zero when the
        # real answer is "not enough data yet".
        #
        # device_class is deliberately omitted on the kWh sensors: `energy`
        # requires a total/total_increasing state_class, and these are estimates
        # and lookbacks rather than accumulating registers, so declaring it would
        # log a validation warning on every state write. Icons carry the meaning
        # instead.
        template = [{
          sensor = [
            # Today's usage extrapolated to midnight, on the assumption the rest
            # of the day looks like the part already measured. That assumption is
            # weakest in the early hours - overnight is nearly all baseline, so a
            # 6am projection reads low - which is the cost of having the number
            # at all. The 0.04 floor (~58 minutes) only suppresses the window
            # where the divisor is small enough to produce nonsense.
            {
              name = "Electricity Projected Today";
              unique_id = "electricity_projected_today";
              unit_of_measurement = "kWh";
              state_class = "measurement";
              icon = "mdi:chart-timeline-variant";
              state = ''
                {% set used = states('sensor.electricity_daily') | float(-1) %}
                {% set elapsed = (now() - today_at('00:00')).total_seconds() / 86400 %}
                {{ (used / elapsed) | round(1) if (used >= 0 and elapsed >= 0.04) else none }}
              '';
            }
            # Same extrapolation over the billed period. Cycle bounds are derived
            # from the 26th rather than read off the meter's last_reset attribute
            # so the sensor stands alone and cannot be thrown by a restart before
            # the first rollover.
            #
            # Stepping to the neighbouring cycle goes through .replace(day=26)
            # rather than adding a fixed 30 days, so short and long months both
            # land right: -28 days always falls in the previous month (Mar 26 ->
            # Feb 26) and +32 always in the next (Feb 26 -> Mar 30 -> Mar 26).
            #
            # None of this can be learned from the meter. The utility sends every
            # billing-period field empty over zigbee - verified against the
            # device's own device_query, where zigbee:CurrentBillingPeriodStart
            # and CurrentBillingPeriodDuration are both blank - so the 26th is
            # asserted here and must be corrected by hand if a statement moves.
            {
              name = "Electricity Projected Bill Cycle";
              unique_id = "electricity_projected_bill_cycle";
              unit_of_measurement = "kWh";
              state_class = "measurement";
              icon = "mdi:calendar-arrow-right";
              state = ''
                {% set used = states('sensor.electricity_bill_cycle') | float(-1) %}
                {% set anchor = now().replace(day=26, hour=0, minute=0, second=0, microsecond=0) %}
                {% set start = anchor if now() >= anchor else (anchor - timedelta(days=28)).replace(day=26) %}
                {% set next = (start + timedelta(days=32)).replace(day=26) %}
                {% set frac = (now() - start).total_seconds() / (next - start).total_seconds() %}
                {{ (used / frac) | round | int if (used >= 0 and frac >= 0.02) else none }}
              '';
            }
            # utility_meter carries the previous cycle's total on its own
            # last_period attribute, so a completed period needs no extra meter
            # to remember it. The attribute is a string, hence the float cast.
            #
            # Guarded on > 0, not >= 0. A meter that has never completed a cycle
            # reports last_period = 0, and rendering that as a real zero is how
            # "Last Bill" came out as $8.86 - the fixed charge on top of nothing
            # - on the first boot after the bill-cycle meter was added. Zero is
            # not a possible reading here: the house never stops drawing its
            # ~0.6 kW baseline, so a genuine zero period cannot occur and 0 can
            # only ever mean "no completed period yet".
            {
              name = "Electricity Yesterday";
              unique_id = "electricity_yesterday";
              unit_of_measurement = "kWh";
              state_class = "measurement";
              icon = "mdi:calendar-arrow-left";
              state = ''
                {% set v = state_attr('sensor.electricity_daily', 'last_period') | float(-1) %}
                {{ v | round(1) if v > 0 else none }}
              '';
            }
            {
              name = "Electricity Last Bill Cycle";
              unique_id = "electricity_last_bill_cycle";
              unit_of_measurement = "kWh";
              state_class = "measurement";
              icon = "mdi:calendar-arrow-left";
              state = ''
                {% set v = state_attr('sensor.electricity_bill_cycle', 'last_period') | float(-1) %}
                {{ v | round(1) if v > 0 else none }}
              '';
            }
            # Degree days against a 65F base, the usual US balance point. Cooling
            # degree days are max(0, mean - 65) and heating degree days are
            # max(0, 65 - mean), so over one 24h window their sum is exactly
            # |mean - 65| - one sensor covers both seasons and no season switch
            # is needed. Over a 24h window a degree-day is numerically a degree,
            # which is why the unit is F.
            {
              name = "Electricity Degree Days";
              unique_id = "electricity_degree_days";
              unit_of_measurement = "°F";
              state_class = "measurement";
              icon = "mdi:thermometer-lines";
              state = ''
                {% set t = states('sensor.outdoor_temperature_24h') | float(-999) %}
                {{ ((t - 65) | abs | round(1)) if t > -900 else none }}
              '';
            }
            # The normalised number: how much electricity a degree of weather
            # costs. This is what makes two months comparable when one was hotter
            # than the other - a raw kWh total cannot separate "used more" from
            # "it was hotter".
            #
            # Floored at 1 degree day. Near the balance point the house needs
            # essentially no conditioning, so the quotient is baseline load
            # divided by ~0 and swings wildly on a rounding step - the same
            # failure the PM2.5 indoor/outdoor ratio guards against. Mild weather
            # therefore reads unknown, which is honest: on a 64F day there is no
            # weather-driven usage to normalise.
            #
            # Numerator is the projection rather than usage-so-far, so the value
            # is comparable across the day instead of climbing from near zero
            # every midnight.
            {
              name = "Electricity per Degree Day";
              unique_id = "electricity_per_degree_day";
              unit_of_measurement = "kWh/°F";
              state_class = "measurement";
              icon = "mdi:home-thermometer";
              state = ''
                {% set kwh = states('sensor.electricity_projected_today') | float(-1) %}
                {% set dd = states('sensor.electricity_degree_days') | float(-1) %}
                {{ (kwh / dd) | round(2) if (kwh >= 0 and dd >= 1) else none }}
              '';
            }

            # Cost. Computed here rather than through the energy integration's
            # own cost sensor, which multiplies kWh by a single flat price and
            # so cannot represent the fixed customer charge at all - on a light
            # month that charge is most of the error. Doing it in templates also
            # keeps the rate declarative: the energy dashboard stores its price
            # in .storage, set through the UI, where a rate change would be
            # invisible to this repo.
            #
            # Energy-only rows carry no fixed charge; it is levied once per
            # billing period, so it belongs only on the cycle and bill rows.
            {
              name = "Electricity Rate";
              unique_id = "electricity_rate";
              unit_of_measurement = "USD/kWh";
              state_class = "measurement";
              icon = "mdi:cash";
              state = "${toString duquesne.marginal}";
            }
            {
              name = "Electricity Cost Today";
              unique_id = "electricity_cost_today";
              unit_of_measurement = "$";
              state_class = "measurement";
              icon = "mdi:cash-clock";
              state = ''
                {% set kwh = states('sensor.electricity_daily') | float(-1) %}
                {{ (kwh * ${toString duquesne.marginal}) | round(2) if kwh >= 0 else none }}
              '';
            }
            {
              name = "Electricity Cost Bill Cycle";
              unique_id = "electricity_cost_bill_cycle";
              unit_of_measurement = "$";
              state_class = "measurement";
              icon = "mdi:cash-multiple";
              state = ''
                {% set kwh = states('sensor.electricity_bill_cycle') | float(-1) %}
                {{ (${toString duquesne.fixed} + kwh * ${toString duquesne.marginal}) | round(2) if kwh >= 0 else none }}
              '';
            }
            # The headline: what the next statement lands at if the rest of the
            # cycle looks like the part already metered.
            {
              name = "Electricity Projected Bill";
              unique_id = "electricity_projected_bill";
              unit_of_measurement = "$";
              state_class = "measurement";
              icon = "mdi:file-document-outline";
              state = ''
                {% set kwh = states('sensor.electricity_projected_bill_cycle') | float(-1) %}
                {{ (${toString duquesne.fixed} + kwh * ${toString duquesne.marginal}) | round(2) if kwh >= 0 else none }}
              '';
            }
            {
              name = "Electricity Last Bill";
              unique_id = "electricity_last_bill";
              unit_of_measurement = "$";
              state_class = "measurement";
              icon = "mdi:file-document-check-outline";
              state = ''
                {% set kwh = state_attr('sensor.electricity_bill_cycle', 'last_period') | float(-1) %}
                {{ (${toString duquesne.fixed} + kwh * ${toString duquesne.marginal}) | round(2) if kwh > 0 else none }}
              '';
            }
          ];
        }];
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