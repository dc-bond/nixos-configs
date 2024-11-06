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
        #identityFile = "~/.ssh/chris-ed25519.key";
      };
      "vm1" = {
        hostname = "${configVars.vm1Ip}";
        user = "${configVars.userName}";
        port = 28765;
      };
      "aspen" = {
        hostname = "${configVars.aspenIp}";
        user = "${configVars.userName}";
        port = 28766;
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
    pinentryPackage = pkgs.pinentry-rofi; # when enabling rofi in a compositor, requires rofi.nix module active
  };

}