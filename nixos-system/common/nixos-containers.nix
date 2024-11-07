{ 
  config, 
  configVars,
  pkgs, 
  lib,
  ... 
}:

{

  virtualisation.containers.enable = true;

  networking = {
    nat = {
      enable = true;
      externalInterface = "enp0s3";
      internalInterfaces = ["br0"];
      enableIPv6 = false;
    };
    interfaces."br0" = {
      enable = true;
      useDHCP = true;
      ipv4.addresses = [
        {
        address = "${configVars.aspenBridgeSubnet}";
        prefixLength = 24;
        }
      ]; 
    };
  };

}
