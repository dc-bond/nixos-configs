{ 
pkgs,
config,
configVars, 
lib,
... 
}: 

let
  app = "roundcube";
in

{

  sops.secrets.chrisEmailPasswd = {};

  systemd.services.${app}.environment = { 
    SMTP_PASS = "${config.sops.secrets.chrisEmailPasswd.path}";
  };

  services = {

    ${app} = {
      enable = true;
      configureNginx = false;
      maxAttachmentSize = 30;
      dicts = with pkgs.aspellDicts; [ en ];
      database.host = "localhost";
      database.username = "${app}";
      database.dbname = "${app}";
      extraConfig = ''
        $config['default_host'] = 'ssl://mail.privateemail.com';
        $config['default_port'] = 993;
        $config['smtp_server'] = 'ssl://mail.privateemail.com';
        $config['smtp_port'] = 465;
        $config['smtp_user'] = '${configVars.users.chris.email}';
        $config['smtp_pass'] = '$SMTP_PASS';
        $config['smtp_auth_type'] = 'LOGIN';
      '';
    };
    
    postgresqlBackup = {
      databases = [ "${app}" ];
    };

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "${app}.${configVars.domain2}" = {
          forceSSL = false;
          enableACME = false;
          root = pkgs.roundcube;
          locations."/" = {
            index = "index.php";
            priority = 1100;
            extraConfig = ''
              add_header Cache-Control 'public, max-age=604800, must-revalidate';
            '';
          };
          locations."~ ^/(SQL|bin|config|logs|temp|vendor)/" = {
            priority = 3110;
            extraConfig = ''
              return 404;
            '';
          };
          locations."~ ^/(CHANGELOG.md|INSTALL|LICENSE|README.md|SECURITY.md|UPGRADING|composer.json|composer.lock)" =
            {
              priority = 3120;
              extraConfig = ''
                return 404;
              '';
            };
          locations."~* \\.php(/|$)" = {
            priority = 3130;
            extraConfig = ''
              fastcgi_pass unix:${config.services.phpfpm.pools.roundcube.socket};
              fastcgi_param PATH_INFO $fastcgi_path_info;
              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              include ${config.services.nginx.package}/conf/fastcgi.conf;
            '';
          };
          listen = [{addr = "127.0.0.1"; port = 4415;}];
        };
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [ "secure-headers" ];
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
            url = "http://127.0.0.1:4415";
          }
          ];
        };
      };
    };

  };

}