{ 
  pkgs,
  lib,
  config, 
  ... 
}: 

{

  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ 
      gasket 
      apex 
    ];
    kernelModules = [ 
      "gasket" 
      "apex" 
    ];
  };

  environment.systemPackages = with pkgs; [ libedgetpu ];

# test
# dmesg | grep apex
# lspci -nn | grep 089a  # Coral Edge TPU has PCI ID 1ac1:089a
# edgetpu_detect

}