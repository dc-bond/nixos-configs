{
  pkgs,
  lib,
  config,
  configVars,
  ...
}:

let
  #app = "calibre-server";
  app2 = "calibre-web";
in

{

  services = {

    #"${app}" = {
    #  enable = true;
    #  port = 7189;
    #  libraries = [ "${storage.mountPoint}/media/ebooks/calibre/" ];
    #};

    "${app2}" = {
      enable = true;
      user = "calibre-web";
      group = "calibre-web";
      listen = {
       ip = "127.0.0.1";
       port = 7190;
      };
      options = {
        reverseProxyAuth.enable = true;
        calibreLibrary = "${config.bulkStorage.path}/media/ebooks/calibre/";
        enableBookUploading = true;
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers = {
        #${app} = {
        #  entrypoints = ["websecure"];
        #  rule = "Host(`${app}.${configVars.domain2}`)";
        #  service = "${app}";
        #  middlewares = [
        #    "secure-headers"
        #  ];
        #  tls = {
        #    certResolver = "cloudflareDns";
        #    options = "tls-13@file";
        #  };
        #};
        ${app2} = {
          entrypoints = ["websecure"];
          rule = "Host(`${app2}.${configVars.domain2}`)";
          service = "${app2}";
          middlewares = [
            "trusted-allow"
            "secure-headers"
          ];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
      };
      services = {
        #${app} = {
        #  loadBalancer = {
        #    passHostHeader = true;
        #    servers = [
        #    {
        #      url = "http://127.0.0.1:7189";
        #    }
        #    ];
        #  };
        #};
        ${app2} = {
          loadBalancer = {
            passHostHeader = true;
            servers = [
            {
              url = "http://127.0.0.1:7190";
            }
            ];
          };
        };
      };
    };

  };

}