{ 
  pkgs, 
  config,
  configVars,
  ... 
}: 

{

  #systemd = {
  #  services.lsyncd = {
  #    description = "lsyncd service for syncing beancount files to cypress";
  #    after = [ "network.target" ];
  #    wants = [ "network.target" ];
  #    wantedBy = [ "multi-user.target" ];
  #    serviceConfig = {
  #      ExecStart = "${pkgs.lsyncd}/bin/lsyncd /etc/lsyncd.conf";
  #      Restart = "always";
  #      User = "chris";
  #    };
  #  };
  #};

  environment = {
    systemPackages = with pkgs; [ lsyncd ];
    etc."lsyncd.conf".text = ''
      settings {
        maxDelays  = 10,
      }
      sync {
        default.rsyncssh,
        source = "/home/chris/nextcloud-local/Bond/Financial/bond-ledger",
        host = "cypress",
        targetdir = "/home/chris/bond-ledger",
        delay = 10,
        rsync  = {
          compress = true,
          archive = true,
          verbose = true,
        }
      }
    '';
  };

}