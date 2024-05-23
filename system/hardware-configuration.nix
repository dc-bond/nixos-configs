{ config, lib, pkgs, modulesPath, ... }:

{
  
  imports = [ ];

  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/4ab2b6dc-6708-4105-84ae-9749044f11b0";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/6c809478-1445-4e6e-b6e9-a998bca65ab9";

  fileSystems."/boot" = { 
    device = "/dev/disk/by-uuid/B2B2-0622";
    fsType = "vfat";
  };

  swapDevices = [
    {
      device = "/.swapfile"; 
      size = 2048; 
    }
  ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation.virtualbox.guest.enable = true;

}