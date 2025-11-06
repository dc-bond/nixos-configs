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
        capi.credentialsFile = "/var/lib/crowdsec/state/capi-credentials.yaml";
        console.tokenFile = "/var/lib/crowdsec/state/console-token";
      };
      hub = {
        collections = [
          # reads from syslog acquisition
          "crowdsecurity/linux" # linux system protection
          "crowdsecurity/sshd" # ssh brute-force protection
          # reads from traefik acquisition
          "crowdsecurity/traefik" # traefik reverse proxy protection
          "crowdsecurity/base-http-scenarios" # generic http attacks
          "crowdsecurity/http-cve" # known http exploits
        ];
      };
      localConfig = {
        acquisitions = [
          {
            source = "journalctl";
            journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
            labels = {
              type = "syslog";
              program = "sshd";
            };
          }
          {
            filenames = [ "/var/log/traefik/access.log" ];
            labels.type = "traefik";
          }
        ];
        parsers.s02Enrich = [
          {
            name = "homelab/whitelist-trusted-networks";
            description = "whitelist internal and vpn networks";
            whitelist = {
              reason = "trusted internal networks";
              cidr = [
                "192.168.1.0/24" # home LAN including aspen services (e.g. uptime kuma)
                "100.64.0.0/10" # tailscale vpn range
              ];
              #ip = [
              #  ""
              #];
            };
          }
        ]; 
      };
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

  programs.zsh = {
    shellAliases = {
      csmetrics = "sudo cscli metrics";
      csbans = "sudo cscli decisions list";
      csalerts = "sudo cscli alerts list --limit 10";
      csbouncers = "sudo cscli bouncers list";
    };
    interactiveShellInit = '' 
      # function to unban an ip
      csunban() {
        if [ -z "$1" ]; then
          echo "Usage: csunban <IP>"
          return 1
        fi
        sudo cscli decisions delete --ip "$1"
      }
    '';
  };

}