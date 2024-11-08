{ 
  config, 
  configVars,
  pkgs, 
  lib,
  ... 
}:

{

  virtualisation.containers.enable = true;

  #networking = {
  #  #nat = {
  #  #  enable = true;
  #  #  externalInterface = "enp0s3";
  #  #  internalInterfaces = ["br0"];
  #  #  enableIPv6 = false;
  #  #};
  #  #bridges.br0.interfaces = ["enp0s3"];
  #  #interfaces.br0 = {
  #  #  name = "br0";
  #  #  useDHCP = true;
  #  #  ipv4.addresses = [
  #  #    {
  #  #    address = "172.18.1.2";
  #  #    prefixLength = 24;
  #  #    }
  #  #  ]; 
  #  #};
  #};

}
