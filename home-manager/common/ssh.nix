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
  #  #templates = {
  #  #  template1.content = 
  #  #    ''
  #  #    ${config.sops.secrets."opticonUrl"};
  #  #    '';
  #  #  #"template2".content = ''${config.sops.placeholder."secret2"}'';       
  #  #};
  #};

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "opticon" = {
        hostname = "vpn.opticon.dev";
        user = "xixor";
        port = 39800;
        #port = "cat ${config.sops.secrets.opticonSshPort.path}";
        #identityFile = "~/.ssh/chris-ed25519.key";
        #identityFile = "~/.ssh/chris-gpgauth-yubikey321.pub";
      };
    };
  };

}