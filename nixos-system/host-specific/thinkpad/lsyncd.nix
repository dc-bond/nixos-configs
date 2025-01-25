{ 
  pkgs, 
  config, 
  ... 
}: 

{

  systemd = {
    services.lsyncd = {
      description = "lsyncd service for syncing beancount files to cypress";
      after = [ "network.target" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.lsyncd}/bin/lsyncd /etc/lsyncd.conf";
        Restart = "always";
        RestartSec = 5;
      };
    };
    tmpfiles.rules = [ "f /etc/lsyncd.conf 0644 root root -" ];
  };

  environment = {
    systemPackages = with pkgs; [ lsyncd ];
    etc."lsyncd.conf".text = ''
      settings {
        logfile    = "/var/log/lsyncd.log",
        statusFile = "/var/log/lsyncd.status",
        maxDelays  = 10,
      }
      sync {
        default.rsyncssh,
        source = "/home/chris/nextcloud-local/Bond/Financial/bond-ledger",
        host = "cypress",
        targetdir = "/var/lib/docker/volumes/fava/_data",
        delay = 10,
        rsync  = {
          compress = true,
          archive = true,
          verbose = true,
          _extra = {"--delete"}
        }
      }
    ''
  };

}