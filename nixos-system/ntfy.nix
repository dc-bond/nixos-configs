{
  pkgs,
  config,
  lib,
  configVars,
  ...
}:

# NTFY - Self-hosted push notification service
#
# TOPICS:
#   homelab-info      - Backup success, service restarts, routine notifications
#   homelab-alerts    - Backup failures, Prometheus/Alertmanager alerts
#
# SENDING NOTIFICATIONS:
#   curl -d "message text" https://${app}.${configVars.domain2}/homelab-critical
#   curl -d "message" -H "Priority: urgent" https://${app}.${configVars.domain2}/homelab-critical
#   curl -d "message" -H "Tags: warning,skull" https://${app}.${configVars.domain2}/homelab-info
#
# MOBILE APP SETUP:
#   1. Install ntfy app (iOS/Android)
#   2. Add server: https://${app}.${configVars.domain2}
#   3. Subscribe to topics: homelab-info, homelab-alerts
#   4. Set notification priority (critical topics should override DND)

let

  app = "ntfy";

  # declaratively provision admin user using password hash from secrets
  ntfyProvisionAdminScript = pkgs.writeShellScript "${app}-provision-admin" ''
    # wait for ntfy to create auth database
    echo "Waiting for ntfy auth database..."
    for i in {1..30}; do
      if [ -f /var/lib/ntfy-sh/user.db ]; then
        echo "Database found"
        break
      fi
      sleep 1
    done

    if [ ! -f /var/lib/ntfy-sh/user.db ]; then
      echo "ERROR: ntfy auth database not found after 30 seconds"
      exit 1
    fi

    # read password hash from SOPS secret
    PASSWORD_HASH=$(cat ${config.sops.secrets.ntfyAdminPasswdHash.path})
    USERNAME="${configVars.users.chris.email}"

    # check if admin user already exists
    if ${pkgs.ntfy-sh}/bin/ntfy user list --auth-file /var/lib/ntfy-sh/user.db | grep -q "user $USERNAME"; then
      echo "Admin user $USERNAME already exists"
    else
      echo "Creating admin user: $USERNAME"
      # Insert user directly into SQLite database with bcrypt hash
      # Format: username, password_hash (bcrypt), role (admin=1, user=0)
      ${pkgs.sqlite}/bin/sqlite3 /var/lib/ntfy-sh/user.db \
        "INSERT INTO user (user, pass, role) VALUES ('$USERNAME', '$PASSWORD_HASH', 'admin');"
      echo "Admin user created successfully"
    fi
  '';

in

{

  sops.secrets.ntfyAdminPasswdHash = {};

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://${app}.${configVars.domain2}";
      behind-proxy = true;
      auth-default-access = "deny-all";

      # iOS push notification support - forwards poll requests to upstream ntfy.sh
      upstream-base-url = "https://ntfy.sh";

      cache-duration = "168h"; # 7 days
      visitor-request-limit-burst = 100;
      visitor-request-limit-replenish = "10s";
      visitor-message-daily-limit = 1000;
      attachment-total-size-limit = "500M";
      attachment-file-size-limit = "50M";
      attachment-expiry-duration = "168h"; # 7 days
      message-size-limit = "8K";
      log-level = "info";
      enable-login = true;
      enable-signup = false;
      enable-reservations = false;
    };
  };

  systemd.services.ntfy-sh = {
    postStart = ''
      ${ntfyProvisionAdminScript}
    '';
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
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
        passHostHeader = true;
        servers = [{
          url = "http://127.0.0.1:2586";
        }];
      };
    };
  };

}