{ 
  pkgs, 
  ... 
}: 

{

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3; # only display last 3 generations
      };
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = {
      btrfs = true;
      ext4 = true;
    };
    kernel.sysctl = { "vm.swappiness" = 30;};
    initrd = {
      includeDefaultModules = false;
      supportedFilesystems = {
        btrfs = true;
        ext4 = true;
      };
      compressor = "xz";
      compressorArgs = [ 
        "-9" 
        "-T" 
        "0" 
      ];
      preLVMCommands = ''
        ${pkgs.kbd}/bin/setleds +num
      '';
    };
  };

}