{
  config,
  configVars,
  lib,
  ...
}:

let
  bootLoader = configVars.hosts.${config.networking.hostName}.bootLoader;
in

{

  boot = {

    loader = {
      systemd-boot = lib.mkIf (bootLoader == "systemd-boot") {
        enable = true;
        configurationLimit = 5; # only display last 5 generations
      };
      grub = lib.mkIf (bootLoader == "grub") {
        enable = true;
        efiSupport = false;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = bootLoader == "systemd-boot";
    };

    supportedFilesystems = {
      btrfs = true;
      ext4 = true;
    };

    kernel.sysctl = {
      "vm.swappiness" = lib.mkDefault 30; # baseline for disk-swap-only hosts; zram.nix raises this to 180 on hosts that import it
      "kernel.kptr_restrict" = 2;         # hide kernel pointers
      "net.core.bpf_jit_harden" = 2;      # harden BPF JIT compiler
      #"kernel.dmesg_restrict" = 1;        # restrict dmesg access
      #"kernel.sysrq" = 0;                 # disable SysRq key
    };

    #kernelParams = [ "quiet" ];

    # default 4 also prints KERN_ERR to the console, which lands on top of the
    # greeter when a device logs an error after boot - the intel bluetooth
    # adapter re-enumerating is the usual one. 3 keeps CRIT and above on the
    # console; everything is still in the journal
    consoleLogLevel = 3;
    
    initrd = {
      supportedFilesystems = {
        btrfs = true;
        ext4 = true;
      };
    };

  };

}