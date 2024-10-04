{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "opticon" = {
        hostname = "vpn.opticon.dev";
        user = "xixor";
        port = 39800;
        #identityFile = "~/.ssh/chris-ed25519.key";
      };
      "thinkpad-dock" = {
        hostname = "192.168.1.62";
        user = "chris";
        port = 28764;
      };
    };
  };
  
  services.ssh-agent.enable = true; # ensure ssh-agent is running
  
}