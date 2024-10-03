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
        identityFile = "/root/.ssh/root@vm1.key";
      };
      "opticon" = {
        hostname = "opticon.dev";
        user = "xixor";
        port = 39800;
      };
    };
  };

}