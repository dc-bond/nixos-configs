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

    settings = {
      #"*" = {
      #  ConnectTimeout = 10;
      #  ServerAliveInterval = 5;
      #  ServerAliveCountMax = 3;
      #};
      "aspen" = {
        HostName = configVars.hosts.aspen.networking.ipv4;
        User = config.home.username;
        Port = 28766;
      };
      "aspen-wan" = {
        HostName = "ssh.${configVars.domain1}";
        User = config.home.username;
        Port = 28766;
      };
      "aspen-tailscale" = {
        HostName = configVars.hosts.aspen.networking.tailscaleIp;
        User = config.home.username;
        Port = 22;
      };
      "juniper" = {
        HostName = configVars.hosts.juniper.networking.ipv4;
        User = config.home.username;
        Port = 28764;
      };
      "juniper-tailscale" = {
        HostName = configVars.hosts.juniper.networking.tailscaleIp;
        User = config.home.username;
        Port = 22;
      };
      "cypress-tailscale" = {
        HostName = configVars.hosts.cypress.networking.tailscaleIp;
        User = config.home.username;
        Port = 22;
      };
      "thinkpad-tailscale" = {
        HostName = configVars.hosts.thinkpad.networking.tailscaleIp;
        User = config.home.username;
        Port = 22;
      };
      "alder-tailscale" = { # alder deprecated, not deployed
        HostName = configVars.hosts.alder.networking.tailscaleIp;
        User = "eric";
        Port = 22;
      };
      "alder-vnc" = { # alder deprecated, not deployed
        HostName = configVars.hosts.alder.networking.tailscaleIp;
        User = "eric";
        Port = 22;
        LocalForward = [{
          bind.port = 5901;
          host.address = "127.0.0.1";
          host.port = 5900;
        }];
      };
      "kauri-tailscale" = {
        HostName = configVars.hosts.kauri.networking.tailscaleIp;
        User = "danielle";
        Port = 22;
      };
      "kauri-vnc" = {
        HostName = configVars.hosts.kauri.networking.tailscaleIp;
        User = "danielle";
        Port = 22;
        LocalForward = [{
          bind.port = 5900;
          host.address = "127.0.0.1";
          host.port = 5900;
        }];
      };
      "unifi-usg" = {
        HostName = configVars.devices.unifiUsg.ipv4;
        User = "dcbond";
        Port = 22;
      };
      "unifi-uap-livingroom" = {
        HostName = configVars.devices.unifiUapLivingRoom.ipv4;
        User = "dcbond";
        Port = 22;
      };
      "unifi-uap-garage" = {
        HostName = configVars.devices.unifiUapGarage.ipv4;
        User = "dcbond";
        Port = 22;
      };
      "unifi-switch8" = {
        HostName = configVars.devices.unifiSwitch8.ipv4;
        User = "dcbond";
        Port = 22;
      };
      "unifi-switch8-lite" = {
        HostName = configVars.devices.unifiSwitch8Lite.ipv4;
        User = "dcbond";
        Port = 22;
      };
    };
  };
  
  services.ssh-agent.enable = false; # ensure ssh-agent is not running because gpg-agent activated to serve ssh instead
  
  services.gpg-agent = {
    enable = true; # this setting adds export GPG_TTY lines to user's .zshrc and starts the agent on login
    enableScDaemon = true; # allow gpg-agent to use smartcards (e.g. yubikey)
    enableSshSupport = true; # this setting adds 'gpg-connect-agent updatestartuptty /bye' to user's .zshrc to replace ssh-agent SSH_AUTH_SOCK with gpg-agent instead
    sshKeys = [ # adds auth subkey keygrip identifier to .gnupg/sshcontrol file and load gpg auth private key into gpg-agent
      #"DB9ADBBE6FBD1F0E694AF25D012321D46E090E61"
      "0220A39C45CB35A72692C72BC35B8E300BDA0690"
    ];
    pinentry.package = lib.mkDefault pkgs.pinentry-curses; # curses default unless rofi module is imported
  };

}