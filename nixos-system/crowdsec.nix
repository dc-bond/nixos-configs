{ 
  inputs,
  pkgs, 
  config,
  lib,
  ... 
}:

let
  crowdsecApiPort = 8590;
in

{

  #sops.secrets.crowdsecConsoleToken = {
  #  owner = "crowdsec";
  #  group = "crowdsec";
  #};

  services = {

    crowdsec = {
      enable = true;
      package = pkgs.unstable.crowdsec;
      settings = {
        general.api.server = {
          enable = true;
          listen_uri = "127.0.0.1:${toString crowdsecApiPort}";
          console_path = "/etc/crowdsec/console.yaml";
        };
        lapi.credentialsFile = "/var/lib/crowdsec/state/lapi-credentials.yaml";
        capi.credentialsFile = "/var/lib/crowdsec/state/capi-credentials.yaml";
        #console = {
        #  configuration = {
        #    share_manual_decisions = true;
        #    share_tainted = false;
        #    share_custom = false;
        #    share_context = true;
        #  };
        #  tokenFile = config.sops.secrets.crowdsecConsoleToken.path; # possible upstream bug with this - automatic enrollment - check after migrate to 25.11?
        #};
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
                "100.64.0.0/10" # tailscale vpn range
              ] ++ lib.optional (config.networking.hostName == "aspen") "192.168.1.0/24"; # home lan including uptime-kuma pings to internal services not routed through cloudflare
              #ip = [
              #  "" # don't want to expose home wan here so using imperative approach below
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

# imperative whitelist home wan ip (for uptime-kuma pings routed through cloudflare to public-facing services) TO-DO - make this more declarative somehow

# create an allowlist if it doesn't exist
  # sudo cscli allowlist create home-wan -d 'Home WAN IP'

# add WAN IP
  # sudo cscli allowlist add home-wan <insert>

# view it
  # sudo cscli allowlist inspect home-wan

# when IP changes, delete old and add new
  # sudo cscli allowlist delete home-wan <old-IP>
  # sudo cscli allowlist add home-wan <new-IP>