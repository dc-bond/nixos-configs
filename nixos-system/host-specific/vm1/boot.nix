{ 
  pkgs, 
  ... 
}: 

{

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5; # only display last 5 generations
      };
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems.btrfs = true;
    kernel.sysctl = { "vm.swappiness" = 30;};
    initrd = {
      supportedFilesystems.btrfs = true;
      preLVMCommands = ''
        ${pkgs.kbd}/bin/setleds +num
      '';
      #postDeviceCommands = lib.mkAfter ''
      #  mkdir /btrfs_tmp

      #  mount /dev/mapper/cryptroot /btrfs_tmp

      #  if [[ -e /btrfs_tmp/root ]]; then
      #    mkdir -p /btrfs_tmp/old_roots
      #    timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
      #    mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      #  fi

      #  delete_subvolume_recursively() {
      #    IFS=$'\n'
      #    for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
      #        delete_subvolume_recursively "/btrfs_tmp/$i"
      #    done
      #    btrfs subvolume delete "$1"
      #  }

      #  for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
      #    delete_subvolume_recursively "$i"
      #  done

      #  btrfs subvolume create /btrfs_tmp/root

      #  umount /btrfs_tmp
      #'';
    };
  };

}