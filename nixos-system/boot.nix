{ 
  pkgs, 
  config,
  lib,
  ... 
}: 

{

  boot = {

    loader = {
      systemd-boot = lib.mkIf (lib.elem config.networking.hostName ["thinkpad" "cypress" "aspen"]) {
        enable = true;
        configurationLimit = 5; # only display last 5 generations
      };
      grub = lib.mkIf (config.networking.hostName == "juniper") {
        enable = true;
        efiSupport = false;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = lib.elem config.networking.hostName ["thinkpad" "cypress" "aspen"]; # this sets to "true", while excluded systems default to "false"
    };

    supportedFilesystems = {
      btrfs = true;
      ext4 = true;
    };

    kernel.sysctl = { "vm.swappiness" = 30; };
    
    initrd = {
      supportedFilesystems = {
        btrfs = true;
        ext4 = true;
      };
      preLVMCommands = ''
        ${pkgs.kbd}/bin/setleds +num
      '';
    };

  };

}