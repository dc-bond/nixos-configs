{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/chris@vm1.key";
      };
      "opticon" = {
        hostname = "vpn.opticon.dev";
        user = "xixor";
        port = 39800;
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