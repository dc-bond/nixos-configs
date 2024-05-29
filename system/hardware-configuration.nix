{ config, lib, pkgs, modulesPath, ... }:

{
  
  imports = [ ];

  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  #boot.kernelParams = [ "nomodeset" ]; # enable to troubleshoot boot graphics issues

  fileSystems."/" = {
    device = "/dev/disk/by-label/cryptroot";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."cryptroot".device = "/dev/nvme0n1p2";

  fileSystems."/boot" = { 
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [
    {
      device = "/.swapfile"; 
      size = 16384; 
    }
  ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation.virtualbox.guest.enable = true;

}