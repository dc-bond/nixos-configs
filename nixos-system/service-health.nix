{
  pkgs,
  config,
  lib,
  configVars,
  ...
}:

let

  # webhook notification script for health check failures
  healthCheckFailureWebhookScript = serviceName: pkgs.writeShellScriptBin "healthCheckFailureWebhook-${serviceName}" ''
    #!/bin/bash

    TIMESTAMP="$(date "+%Y-%m-%d %H:%M:%S")"
    HOSTNAME="${config.networking.hostName}"
    SERVICE_NAME="${serviceName}"

    # get failure count from state file
    FAILURE_COUNT=$(cat /var/lib/healthcheck/${serviceName}/failure-count 2>/dev/null || echo "0")

    ${pkgs.curl}/bin/curl -X POST \
      -H "Content-Type: application/json" \
      -d @- \
      "${configVars.webhooks.matrixBackupNotifications}" <<EOF
    {
      "text": "🚨 **Health Check FAILED - $HOSTNAME**\n\n**Service**: $SERVICE_NAME\n**Status**: Unhealthy\n**Time**: $TIMESTAMP\n**Failures**: $FAILURE_COUNT consecutive"
    }
    EOF
  '';

  # webhook notification script for health check recoveries
  healthCheckRecoveryWebhookScript = serviceName: pkgs.writeShellScriptBin "healthCheckRecoveryWebhook-${serviceName}" ''
    #!/bin/bash

    TIMESTAMP="$(date "+%Y-%m-%d %H:%M:%S")"
    HOSTNAME="${config.networking.hostName}"
    SERVICE_NAME="${serviceName}"

    ${pkgs.curl}/bin/curl -X POST \
      -H "Content-Type: application/json" \
      -d @- \
      "${configVars.webhooks.matrixBackupNotifications}" <<EOF
    {
      "text": "✅ **Health Check RECOVERED - $HOSTNAME**\n\n**Service**: $SERVICE_NAME\n**Status**: Healthy\n**Time**: $TIMESTAMP\n\nService has recovered and is responding normally."
    }
    EOF
  '';

  # build systemd services and timers for all enabled health checks
  mkHealthCheckService = serviceName: cfg: let
    failureScript = healthCheckFailureWebhookScript serviceName;
    recoveryScript = healthCheckRecoveryWebhookScript serviceName;
  in {
    "healthcheck-${serviceName}" = {
      description = "Health check for ${serviceName}";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "healthcheck-${serviceName}-check" ''
          set -euo pipefail

          STATE_DIR="/var/lib/healthcheck/${serviceName}"
          FAILURE_COUNT_FILE="$STATE_DIR/failure-count"
          FAILED_MARKER="$STATE_DIR/failed"

          # ensure state directory exists
          mkdir -p "$STATE_DIR"

          # run the health check
          if ${cfg.checkCommand}; then
            # success - reset failure count and remove failed marker
            echo "0" > "$FAILURE_COUNT_FILE"
            if [ -f "$FAILED_MARKER" ]; then
              rm "$FAILED_MARKER"
              ${lib.optionalString cfg.notifyOnRecovery ''
                ${recoveryScript}/bin/healthCheckRecoveryWebhook-${serviceName}
              ''}
            fi
            exit 0
          else
            # failure - increment failure count
            CURRENT_COUNT=$(cat "$FAILURE_COUNT_FILE" 2>/dev/null || echo "0")
            NEW_COUNT=$((CURRENT_COUNT + 1))
            echo "$NEW_COUNT" > "$FAILURE_COUNT_FILE"

            # check if we've hit the threshold for notification
            if [ "$NEW_COUNT" -ge ${toString cfg.consecutiveFailures} ]; then
              # only create failed marker and notify once we hit threshold
              if [ ! -f "$FAILED_MARKER" ]; then
                touch "$FAILED_MARKER"
                ${lib.optionalString cfg.notifyOnFailure ''
                  ${failureScript}/bin/healthCheckFailureWebhook-${serviceName}
                ''}
              fi
            fi
            exit 1
          fi
        '';
      };
    };

  };

  mkHealthCheckTimer = serviceName: cfg: {
    "healthcheck-${serviceName}" = {
      description = "Health check timer for ${serviceName}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = cfg.initialDelay;
        OnUnitActiveSec = cfg.checkInterval;
        Unit = "healthcheck-${serviceName}.service";
      };
    };
  };

  # collect all enabled health checks
  enabledHealthChecks = lib.filterAttrs (name: cfg: cfg.enable) config.serviceHealth;

in

{

  options.serviceHealth = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        enable = lib.mkEnableOption "health check monitoring for this service";

        checkCommand = lib.mkOption {
          type = lib.types.str;
          description = "Command to run for health check. Should exit 0 on success, non-zero on failure.";
          example = "\${pkgs.curl}/bin/curl -f http://127.0.0.1:8080/health";
        };

        checkInterval = lib.mkOption {
          type = lib.types.str;
          default = "5min";
          description = "How often to run the health check (systemd time format)";
          example = "2min";
        };

        initialDelay = lib.mkOption {
          type = lib.types.str;
          default = "1min";
          description = "Initial delay after boot before first health check (systemd time format)";
        };

        notifyOnFailure = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Send webhook notification when health check fails";
        };

        notifyOnRecovery = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Send webhook notification when service recovers";
        };

        consecutiveFailures = lib.mkOption {
          type = lib.types.int;
          default = 2;
          description = "Number of consecutive failures before sending notification";
        };
      };
    });
    default = {};
    description = "Health check configurations for services";
  };

  config = lib.mkIf (enabledHealthChecks != {}) {

    # create parent health check state directory
    systemd.tmpfiles.rules = [
      "d /var/lib/healthcheck 0755 root root -"
    ];

    systemd.services = lib.mkMerge (lib.mapAttrsToList mkHealthCheckService enabledHealthChecks);

    systemd.timers = lib.mkMerge (lib.mapAttrsToList mkHealthCheckTimer enabledHealthChecks);

  };

}
