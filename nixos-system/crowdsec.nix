{ 
  inputs,
  pkgs, 
  config,
  ... 
}:

let
  crowdsecApiPort = 8590;
in

{

  imports = [ 
    "${inputs.nixpkgs-unstable}/nixos/modules/services/security/crowdsec.nix" 
    "${inputs.nixpkgs-unstable}/nixos/modules/services/security/crowdsec-firewall-bouncer.nix"
  ];

  services = {

    crowdsec = {
      enable = true;
      package = pkgs.unstable.crowdsec;
      settings = {
        general.api.server = {
          enable = true;
          listen_uri = "127.0.0.1:${toString crowdsecApiPort}";
        };
        lapi.credentialsFile = "/var/lib/crowdsec/state/lapi-credentials.yaml";
      };
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
      settings = {
        api_url = "http://127.0.0.1:${toString crowdsecApiPort}/";
      };
    };
  
  };

}