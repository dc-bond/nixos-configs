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
      "opticon" = {
        hostname = "vpn.${configVars.domain2}";
        user = "xixor";
        port = 39800;
      };
      "opticon-tailscale" = {
        hostname = "${configVars.opticonTailscaleIp}";
        user = "xixor";
        port = 22;
      };
      "cypress" = {
        hostname = "${configVars.cypressLanIp}";
        user = "${configVars.userName}";
        port = 28761;
      };
      "cypress-tailscale" = {
        hostname = "${configVars.cypressTailscaleIp}";
        user = "${configVars.userName}";
        port = 22;
      };
      "aspen" = {
        hostname = "${configVars.aspenLanIp}";
        user = "${configVars.userName}";
        port = 28766;
      };
      #"aspen-tailscale" = {
      #  hostname = "${configVars.aspenTailscaleIp}";
      #  user = "${configVars.userName}";
      #  port = 22;
      #};
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
    pinentryPackage = pkgs.pinentry-rofi; # when enabling rofi in a compositor, requires rofi.nix module active
  };

}