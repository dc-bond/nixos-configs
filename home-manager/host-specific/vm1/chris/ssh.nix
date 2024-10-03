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
        hostname = "opticon.dev";
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

}