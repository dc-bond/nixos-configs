{ 
  pkgs, 
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
        #identityFile = "~/.ssh/chris-gpgauth-yubikey321.pub";
      };
    };
  };

}