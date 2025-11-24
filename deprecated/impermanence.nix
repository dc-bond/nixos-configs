{ 
  inputs,
  lib,
  config,
  ... 
}: 

{

  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  #boot.initrd = {
  #  enable = true;
  #  supportedFilesystems = ["btrfs"];
  #  systemd.services.restore-root = {
  #    description = "Rollback BTRFS rootfs";
  #    wantedBy = ["initrd.target"];
  #    after = ["systemd-cryptsetup@crypted.service"];
  #    before = ["sysroot.mount"];
  #    unitConfig.DefaultDependencies = "no";
  #    serviceConfig.Type = "oneshot";
  #    script = ''
  #      mkdir -p /mnt

  #      # We first mount the btrfs root to /mnt
  #      # so we can manipulate btrfs subvolumes.
  #      mount -o subvol=/ /dev/mapper/crypted /mnt

  #      # While we're tempted to just delete /root and create
  #      # a new snapshot from /root-blank, /root is already
  #      # populated at this point with a number of subvolumes,
  #      # which makes `btrfs subvolume delete` fail.
  #      # So, we remove them first.
  #      btrfs subvolume list -o /mnt/root |
  #      cut -f9 -d' ' |
  #      while read subvolume; do
  #        echo "deleting /$subvolume subvolume..."
  #        btrfs subvolume delete "/mnt/$subvolume"
  #      done &&
  #      echo "deleting /root subvolume..." &&
  #      btrfs subvolume delete /mnt/root

  #      echo "restoring blank /root subvolume..."
  #      btrfs subvolume snapshot /mnt/root-blank /mnt/root

  #      # Once we're done rolling back to a blank snapshot,
  #      # we can unmount /mnt and continue on the boot process.
  #      umount /mnt
  #    '';
  #  };
  #};

  environment.persistence."/persist" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      #{ directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
    ];
    files = [
      "/etc/machine-id"
      #{ file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
    ];
    #users.chris = {
    #  directories = [
    #    #"Downloads"
    #    #"Documents"
    #    #{ directory = ".gnupg"; mode = "0700"; }
    #    #{ directory = ".ssh"; mode = "0700"; }
    #    #{ directory = ".nixops"; mode = "0700"; }
    #    #{ directory = ".local/share/keyrings"; mode = "0700"; }
    #    #".local/share/direnv"
    #  ];
    #  #files = [
    #  #  ".screenrc"
    #  #];
    #};
  };

}