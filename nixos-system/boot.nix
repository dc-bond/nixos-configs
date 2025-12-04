{ 
  pkgs, 
  config,
  configVars,
  lib,
  ... 
}: 

let
  hostData = configVars.hosts.${config.networking.hostName};
in

{

  boot = {

    loader = {
      systemd-boot = lib.mkIf (hostData.bootLoader == "systemd-boot") {
        enable = true;
        configurationLimit = 5; # only display last 5 generations
      };
      grub = lib.mkIf (hostData.bootLoader == "grub") {
        enable = true;
        efiSupport = false;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = hostData.bootLoader == "systemd-boot";
    };

    supportedFilesystems = {
      btrfs = true;
      ext4 = true;
    };

    kernel.sysctl = { 
      "vm.swappiness" = 30;
      "kernel.kptr_restrict" = 2;         # hide kernel pointers
      "net.core.bpf_jit_harden" = 2;      # harden BPF JIT compiler
      #"kernel.dmesg_restrict" = 1;        # restrict dmesg access
      #"kernel.sysrq" = 0;                 # disable SysRq key
    };

    #kernelParams = [ "quiet" ];
    
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