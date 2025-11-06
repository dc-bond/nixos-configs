{ 
  inputs,
  pkgs, 
  config,
  ... 
}: 

{

  imports = [ 
    "${inputs.nixpkgs-unstable}/nixos/modules/services/security/crowdsec.nix" 
    "${inputs.nixpkgs-unstable}/nixos/modules/services/security/crowdsec-firewall-bouncer.nix"
  ];

  services = {

    crowdsec = {
      enable = true;
      package = pkgs.unstable.crowdsec;
      hub = {
        collections = [
          "crowdsecurity/linux" # linux system protection
          "crowdsecurity/sshd" # ssh brute-force protection
          "crowdsecurity/traefik" # traefik reverse proxy protection
          "crowdsecurity/base-http-scenarios" # generic http attacks
          "crowdsecurity/http-cve" # known http exploits
        ];
      };
      localConfig.acquisitions = [
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
          labels.type = "syslog";
        }
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=traefik.service" ];
          labels.type = "traefik";
        }
      ];
    };

    crowdsec-firewall-bouncer = {
      enable = true;
      package = pkgs.unstable.crowdsec-firewall-bouncer;
      registerBouncer.bouncerName = "firewall-bouncer-${config.networking.hostName}";
    };
  
  };

}