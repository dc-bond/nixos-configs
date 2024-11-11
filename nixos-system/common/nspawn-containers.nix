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
    #bridges."br0".interfaces = [ "enp0s3" ];
    #interfaces = {
    #  #"br0".useDHCP = true; # for dhcp address assignment
    #  "br0".ipv4.addresses = [ # for static address assignment
    #    {
    #    address = "${configVars.uptime-kumaVethIp}";
    #    prefixLength = 24;
    #    }
    #  ];
    #};
    nat = {
      enable = true;
      externalInterface = "enp0s3";
      #internalInterfaces = ["ve-uptime-kuma"];
      enableIPv6 = true;
    };
  };

}