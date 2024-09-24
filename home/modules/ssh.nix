{ 
  pkgs,
  config,
  ... 
}: 

{

  #sops = {
  #  secrets = {
  #    opticonUrl = {};
  #    opticonSshPort = {};
  #  };
  #};

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "opticon" = {
        hostname = "vpn.opticon.dev";
        #hostname = "${config.sops.secrets.opticonUrl.path}";
        user = "xixor";
        port = 39800;
        #port = "${config.sops.secrets.opticonSshPort.path}";
        #identityFile = "~/.ssh/chris-ed25519.key";
        #identityFile = "~/.ssh/chris-gpgauth-yubikey321.pub";
      };
    };
  };

}