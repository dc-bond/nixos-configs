{ 
  config, 
  pkgs, 
  configVars,
  ... 
}:

let
  app = "authelia";
in

{

  sops.secrets = {
    autheliaJwtSecret = {
      owner = config.users.users.${app}.name;
      group = config.users.users.${app}.group;
      mode = "0440";
    };
    autheliaStorageEncryptionKey = {
      owner = config.users.users.${app}.name;
      group = config.users.users.${app}.group;
      mode = "0440";
    };
    autheliaSessionSecret = {
      owner = config.users.users.${app}.name;
      group = config.users.users.${app}.group;
      mode = "0440";
    };
    autheliaOidcHmacSecret = {
      owner = config.users.users.${app}.name;
      group = config.users.users.${app}.group;
      mode = "0440";
    };
    #autheliaOidcIssuerPrivateKey = {
    #  owner = config.users.users.${app}.name;
    #  group = config.users.users.${app}.group;
    #  mode = "0440";
    #};
  };

  services.${app}.instances.${configVars.domain3} = {
    enable = true; 
    settings = {
      name = "${app}";
      theme = "dark";
      log = {
        level = "debug";
        format = "text"; 
        file_path = "/var/log/authelia/authelia.log";
        keep_stdout = true;
      };
      server.address = "tcp://:9091/";
      secrets = {
        jwtSecretFile = "${config.sops.secrets.autheliaJwtSecret.path}";
        storageEncryptionKeyFile = "${config.sops.secrets.autheliaStorageEncryptionKey.path}";
        sessionSecretFile = "${config.sops.secrets.autheliaSessionSecret.path}";
        oidcHmacSecretFile = "${config.sops.secrets.autheliaOidcHmacSecret.path}";
        #oidcIssuerPrivateKeyFile = "${config.sops.secrets.autheliaOidcIssuerPrivateKey.path}";
      };
      default_2fa_method = "webauthn";
      telemetry.metrics = {
        enable = false;
        address = "tcp://127.0.0.1:9959";
      };
    };
  }; 

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`identity.${configVars.domain3}`)";
      service = "${app}";
      middlewares = [
        #"auth" 
        #"secure-headers"
      ];
      tls = {
        certResolver = "cloudflareDns";
        options = "tls-13@file";
      };
    };
    services.${app} = {
      loadBalancer = {
        passHostHeader = true;
        servers = [
        {
          url = "http://localhost:9091";
        }
        ];
      };
    };
  };

}