{ 
  inputs, 
  config, 
  lib,
  ... 
}: 

{

  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # wipe / on boot, keep snapshots for 30 days
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount -o subvol=/ /dev/mapper/crypted /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';

  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {

    hideMounts = true;  # hide bind mounts from file manager to reduce visual clutter

    # system-level persistence
    directories = [
      "/var/lib/nixos" # ensures UID/GID mappings stay stable across reboots
      "/var/lib/iwd" # wifi networks & passwords
      "/var/lib/tailscale" # tailscale auth state
      "/var/lib/bluetooth"  # bluetooth pairings
    ];
    files = [
      "/etc/machine-id" # stable machine ID required by systemd, journald, etc.
      "/etc/age/thinkpad-age.key" # SOPS encryption key
      "/etc/ssh/ssh_host_ed25519_key" # SSH server private key - stable identity for remote clients
      "/etc/ssh/ssh_host_ed25519_key.pub" # SSH server public key (derived from private key)
    ];

    # user-level persistence
    users.chris = {
      directories = [
        { directory = ".local/share/keyrings"; mode = "0700"; } # gnome keyring secrets like nextcloud client login, etc.
        { directory = ".config/age"; mode = "0700"; }
        "nextcloud-client" # local nextcloud directory
        ".mozilla" # firefox profiles
        ".config/Element" # matrix e2e keys
        ".config/Nextcloud" # nextcloud sync state
        ".config/VSCodium" # codium editor state, incl. manually-installed extensions not available in nixpkgs
      ];
    };'

  };

  # create parent directories with correct permissions
  systemd.tmpfiles.rules = [
    "d /persist/home/chris 0700 chris users -"
    "d /persist/etc/age 0755 root root -"
  ];
  
}
