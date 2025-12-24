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