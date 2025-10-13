{ 
  pkgs,
  config,
  configVars,
  ... 
}: 

{

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "aspen" = {
        hostname = "${configVars.aspenLanIp}";
        user = "${configVars.chrisUsername}";
        port = 28766;
      };
      "aspen-wan" = {
        hostname = "ssh.${configVars.domain1}";
        user = "${configVars.chrisUsername}";
        port = 28766;
      };
      "aspen-tailscale" = {
        hostname = "${configVars.aspenTailscaleIp}";
        user = "${configVars.chrisUsername}";
        port = 22;
      };
      "cypress" = {
        hostname = "${configVars.cypressLanIp}";
        user = "${configVars.chrisUsername}";
        port = 28761;
      };
      #"cypress-tailscale" = {
      #  hostname = "${configVars.cypressTailscaleIp}";
      #  user = "${configVars.chrisUsername}";
      #  port = 22;
      #};
      "juniper" = {
        hostname = "${configVars.juniperIp}";
        user = "${configVars.chrisUsername}";
        port = 28764;
      };
      "juniper-tailscale" = {
        hostname = "${configVars.juniperTailscaleIp}";
        user = "${configVars.chrisUsername}";
        port = 22;
      };
      "unifi-usg" = {
        hostname = "${configVars.unifiUsgIp}";
        user = "dcbond";
        port = 22;
      };
      "unifi-uap-livingroom" = {
        hostname = "${configVars.unifiUapLivingRoomIp}";
        user = "dcbond";
        port = 22;
      };
      "unifi-uap-garage" = {
        hostname = "${configVars.unifiUapGarageIp}";
        user = "dcbond";
        port = 22;
      };
      "unifi-switch8" = {
        hostname = "${configVars.unifiSwitch8Ip}";
        user = "dcbond";
        port = 22;
      };
      "unifi-switch8-lite" = {
        hostname = "${configVars.unifiSwitch8LiteIp}";
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
  };

}