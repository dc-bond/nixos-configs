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
      #internalInterfaces = ["ve-uptime-kuma"];
      enableIPv6 = false;
    };
  };

}
