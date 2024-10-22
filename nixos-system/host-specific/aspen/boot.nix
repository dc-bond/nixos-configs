{ 
  pkgs, 
  ... 
}: 

{

  boot = {
    loader = {
      grub = {
        forceInstall = true;
        #device = "nodev";
        #extraConfig = ''
        #  serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
        #  terminal_input serial;
        #  terminal_output serial
        #'';
      };
      timeout = 10;
    };
    #kernelParams = [ "console=ttyS0,19200n8" ];
    supportedFilesystems = {
      ext4 = true;
    };
    initrd = {
      supportedFilesystems = {
        ext4 = true;
      };
       turn on keyboard num-lock automatically during boot process
      preLVMCommands = ''
        ${pkgs.kbd}/bin/setleds +num
      '';
    };
  };

}