{ 
  pkgs,
  lib,
  config,
  configVars,
  ... 
}: 

{

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Declaratively manage known SSH host keys
    knownHosts = {
      "aspen" = {
        hostNames = [
          "[${configVars.hosts.aspen.networking.ipv4}]:${toString configVars.hosts.aspen.networking.sshPort}"
          "ssh.${configVars.domain1}"
          configVars.hosts.aspen.networking.tailscaleIp
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAEw3/kxz9yXRd1kHVqyxjU+TJVfZkqfUM0rskhgjZNO";
      };

      "juniper" = {
        hostNames = [
          "[${configVars.hosts.juniper.networking.ipv4}]:${toString configVars.hosts.juniper.networking.sshPort}"
          configVars.hosts.juniper.networking.tailscaleIp
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKO5BIrVxSBDfZfWfOXSx2pSadbg6Fb/l8vXkulEfoB3";
      };

      "cypress" = {
        hostNames = [
          configVars.hosts.cypress.networking.ipv4
          configVars.hosts.cypress.networking.tailscaleIp
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAzRulWkTODGo7qfcwMt8jP3h9kwApc7aEoFiwTQstCL";
      };

      "thinkpad" = {
        hostNames = [
          configVars.hosts.thinkpad.networking.ipv4
          configVars.hosts.thinkpad.networking.tailscaleIp
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9FLj4hn5JMg9O3VxTmOqU5iK6rUzvy0DhMI6ZhWYtP";
      };

      "alder" = {
        hostNames = [
          configVars.hosts.alder.networking.ipv4
          configVars.hosts.alder.networking.tailscaleIp
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMxcJPA4LtJ6UEFN/+7tK9njONRsiozhZ3Y6LdS89vF9";
        # Tailscale interface had different key in old known_hosts - may need update if SSH fails:
        # publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL27Tyjy/tjRf+JZAM6tQ7hlEN/212M5HjZNUIGXHimB";
      };

      "kauri" = {
        hostNames = [
          configVars.hosts.kauri.networking.ipv4
          configVars.hosts.kauri.networking.tailscaleIp
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCzrXOgJLsYhDB+NQAK313SXvcVj8V0B4hmIjHX1b3s";
        # Tailscale interface had different key in old known_hosts - may need update if SSH fails:
        # publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBxptdHxEfVObFDgCiPaQ5tknfzCks10tEuAbMMCAZM3";
      };

      "github" = {
        hostNames = [ "github.com" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      };
    };

    matchBlocks = {
      "*" = {
        extraOptions = {
          ConnectTimeout = "10";
          ServerAliveInterval = "5";
        };
        serverAliveCountMax = 3;
      };
      "aspen" = {
        hostname = configVars.hosts.aspen.networking.ipv4;
        user = config.home.username;
        port = 28766;
      };
      "aspen-wan" = {
        hostname = "ssh.${configVars.domain1}";
        user = config.home.username;
        port = 28766;
      };
      "aspen-tailscale" = {
        hostname = configVars.hosts.aspen.networking.tailscaleIp;
        user = config.home.username;
        port = 22;
      };
      #"cypress" = {
      #  hostname = configVars.hosts.cypress.networking.ipv4;
      #  user = config.home.username;
      #  port = 28761;
      #};
      "cypress-tailscale" = {
        hostname = configVars.hosts.cypress.networking.tailscaleIp;
        user = config.home.username;
        port = 22;
      };
      #"thinkpad" = {
      #  hostname = configVars.hosts.thinkpad.networking.ipv4;
      #  user = config.home.username;
      #  port = 28765;
      #};
      "thinkpad-tailscale" = {
        hostname = configVars.hosts.thinkpad.networking.tailscaleIp;
        user = config.home.username;
        port = 22;
      };
      "juniper" = {
        hostname = configVars.hosts.juniper.networking.ipv4;
        user = config.home.username;
        port = 28764;
      };
      "juniper-tailscale" = {
        hostname = configVars.hosts.juniper.networking.tailscaleIp;
        user = config.home.username;
        port = 22;
      };
      "alder-tailscale" = {
        hostname = configVars.hosts.alder.networking.tailscaleIp;
        user = "eric";
        port = 22;
      };
      "kauri-tailscale" = {
        hostname = configVars.hosts.kauri.networking.tailscaleIp;
        user = "danielle";
        port = 22;
      };
      "unifi-usg" = {
        hostname = configVars.devices.unifiUsg.ipv4;
        user = "dcbond";
        port = 22;
      };
      "unifi-uap-livingroom" = {
        hostname = configVars.devices.unifiUapLivingRoom.ipv4;
        user = "dcbond";
        port = 22;
      };
      "unifi-uap-garage" = {
        hostname = configVars.devices.unifiUapGarage.ipv4;
        user = "dcbond";
        port = 22;
      };
      "unifi-switch8" = {
        hostname = configVars.devices.unifiSwitch8.ipv4;
        user = "dcbond";
        port = 22;
      };
      "unifi-switch8-lite" = {
        hostname = configVars.devices.unifiSwitch8Lite.ipv4;
        user = "dcbond";
        port = 22;
      };
    };
  };
  
  services.ssh-agent.enable = false; # ensure ssh-agent is not running because gpg-agent activated to serve ssh instead
  
  services.gpg-agent = {
    enable = true; # this setting adds export GPG_TTY lines to user's .zshrc and starts the agent on login
    enableScDaemon = true; # allow gpg-agent to use smartcards (e.g. yubikey)
    enableSshSupport = true; # this setting adds 'gpg-connect-agent updatestartuptty /bye' to user's .zshrc to replace ssh-agent SSH_AUTH_SOCK with gpg-agent instead
    sshKeys = [ # adds keygrip identifier to .gnupg/sshcontrol file and load gpg auth private key into gpg-agent
      "DB9ADBBE6FBD1F0E694AF25D012321D46E090E61"
    ];
    pinentry.package = lib.mkDefault pkgs.pinentry-curses; # curses default unless rofi module is imported
    #pinentry.package = pinentryAuto; # should select qt for plasma, rofi for hyprland, and curses for fallback
  };

}