{
  pkgs,
  config,
  lib,
  configVars,
  ...
}:

let

  app = "ntfy";

  # declaratively provision admin user using password from secrets
  ntfyProvisionAdminScript = pkgs.writeShellScript "${app}-provision-admin" ''
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

    PASSWORD=$(cat ${config.sops.secrets.ntfyAdminPasswd.path})
    USERNAME="${configVars.users.chris.email}"
    export NTFY_AUTH_FILE=/var/lib/ntfy-sh/user.db

    if ${pkgs.ntfy-sh}/bin/ntfy user list | grep -q "user $USERNAME"; then
      echo "Admin user $USERNAME already exists"
    else
      echo "Creating admin user: $USERNAME"
      NTFY_PASSWORD="$PASSWORD" ${pkgs.ntfy-sh}/bin/ntfy user add --role=admin "$USERNAME"
      echo "Admin user created successfully"
    fi
  '';

in

{

  sops.secrets.ntfyAdminPasswd = {
    owner = "ntfy-sh";
    group = "ntfy-sh";
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://${app}.${configVars.domain2}";
      behind-proxy = true;
      auth-default-access = "read-write";  # authenticated users get full access
      upstream-base-url = "https://ntfy.sh"; # iOS push notification support?
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