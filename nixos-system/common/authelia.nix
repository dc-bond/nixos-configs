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
      owner = config.users.users.three.name;
      group = config.users.users.three.group;
      mode = "0440";
    };
    autheliaStorageEncryptionKey = {
      owner = config.users.users.three.name;
      group = config.users.users.three.group;
      mode = "0440";
    };
    autheliaSessionSecret = {
      owner = config.users.users.three.name;
      group = config.users.users.three.group;
      mode = "0440";
    };
    autheliaOidcHmacSecret = {
      owner = config.users.users.three.name;
      group = config.users.users.three.group;
      mode = "0440";
    };
    #autheliaOidcIssuerPrivateKey = {
    #  mode = "0440";
    #};
  };

  services.${app}.instances.three = {
    enable = true; 
    settings = {
      #name = "${app}";
      theme = "dark";
      default_2fa_method = "webauthn";
      default_redirection_url = "https://dcbond.com/";
      log = {
        level = "debug";
        format = "text"; 
        file_path = "/var/log/authelia/authelia.log";
        keep_stdout = true;
      };
      telemetry.metrics = {
        enable = false;
        address = "tcp://127.0.0.1:9959";
      };
      server.address = "tcp://:9091/";
    };
    secrets = {
      jwtSecretFile = "${config.sops.secrets.autheliaJwtSecret.path}";
      storageEncryptionKeyFile = "${config.sops.secrets.autheliaStorageEncryptionKey.path}";
      sessionSecretFile = "${config.sops.secrets.autheliaSessionSecret.path}";
      oidcHmacSecretFile = "${config.sops.secrets.autheliaOidcHmacSecret.path}";
      #oidcIssuerPrivateKeyFile = "${config.sops.secrets.autheliaOidcIssuerPrivateKey.path}";
    };
  }; 

      #server = {
      #  host = "127.0.0.1";
      #  port = 9091;
      #};
  
      #authentication_backend = {
      #  file = {
      #    path = "/var/lib/authelia-main/users_database.yml";
      #  };
      #};
  
      #access_control = {
      #  default_policy = "deny";
      #  rules = [
      #    {
      #      domain = ["auth.example.com"];
      #      policy = "bypass";
      #    }
      #    {
      #      domain = ["*.example.com"];
      #      policy = "one_factor";
      #    }
      #  ];
      #};
  
      #session = {
      #  name = "authelia_session";
      #  expiration = "12h";
      #  inactivity = "45m";
      #  remember_me_duration = "1M";
      #  domain = "example.com";
      #  redis.host = "/run/redis-authelia-main/redis.sock";
      #};
  
      #regulation = {
      #  max_retries = 3;
      #  find_time = "5m";
      #  ban_time = "15m";
      #};
  
      #storage = {
      #  local = {
      #    path = "/var/lib/authelia-main/db.sqlite3";
      #  };
      #};
  
      #notifier = {
      #  disable_startup_check = false;
      #  filesystem = {
      #    filename = "/var/lib/authelia-main/notification.txt";
      #  };
      #};

  #services.redis.servers.authelia-main = {
  #  enable = true;
  #  user = "authelia-main";   
  #  port = 0;
  #  unixSocket = "/run/redis-authelia-main/redis.sock";
  #  unixSocketPerm = 600;
  #};

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