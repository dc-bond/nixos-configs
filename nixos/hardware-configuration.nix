{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { 
      device = "/dev/disk/by-label/cryptroot";
      fsType = "ext4";
    };

  #boot.initrd.luks.devices."cryptroot".device = "{{ install_drive }}{{ root_partition_suffix }}";
  boot.initrd.luks.devices."cryptroot".device = "/dev/sda2";

  fileSystems."/boot" =
    { 
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  swapDevices = 
    [
      {
        device = "/.swapfile"; 
        size = 2048; 
      }
    ];

  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s3.useDHCP = lib.mkDefault true; # use with systemd-networkd?

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation.virtualbox.guest.enable = true;
}