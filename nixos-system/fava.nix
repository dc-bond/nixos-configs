{
  pkgs,
  lib,
  config,
  configVars,
  ...
}:

let
  app = "fava";
  ledgerDir = "/var/lib/nextcloud/data/Chris Bond/files/Bond Family/Financial/bond-ledger";
in

{

  systemd.services.${app} = {
    description = "fava web interface for beancount";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    environment = {
      BEANCOUNT_FILE = "${ledgerDir}/master.beancount";
    };
    serviceConfig = {
      # --read-only disables the editor, entry forms, and every write endpoint;
      # ledger edits are made in the beancount files directly, never through fava
      ExecStart = "${pkgs.fava}/bin/fava --host 127.0.0.1 --port 7191 --read-only";
      # nextcloud owns the ledger; no supplementary group needed to read it
      User = "nextcloud";
      Group = "nextcloud";
      Restart = "always";
      RestartSec = "5s";
      # no ReadWritePaths - the whole filesystem is read-only to this unit
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      SystemCallFilter = ["@system-service"];
      LockPersonality = true;
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers = {
      ${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`bond-ledger.${configVars.domain2}`)";
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
    };
    services = {
      ${app} = {
        loadBalancer = {
          serversTransport = "default";
          passHostHeader = true;
          servers = [
          {
            url = "http://127.0.0.1:7191";
          }
          ];
        };
      };
    };
  };

}
