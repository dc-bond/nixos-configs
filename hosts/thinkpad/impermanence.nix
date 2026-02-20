{
  inputs,
  config,
  lib,
  ...
}:

{

  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # tmpfs root - ephemeral in ram, automatically cleared on boot
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  fileSystems."/persist".neededForBoot = true;

  # early bind mount for system age key - must happen before SOPS activation so we do this manually here instead of via impermanence module tooling below (which occurs after sops needs age decryption keys later in boot sequence)
  fileSystems."/etc/age" = {
    device = "/persist/etc/age";
    options = [ "bind" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  environment.persistence."/persist" = {

    hideMounts = true;  # hide bind mounts from file manager to reduce visual clutter

    files = [
      "/etc/machine-id"  # systemd machine identity (prevents new journal directories on each boot)
    ];

    # system-level persistence
    directories = [
      "/var/lib/nixos" # UID/GID mappings to prevent permissions issues on reboot
      "/var/lib/iwd" # wifi networks & passwords
      "/var/lib/bluetooth"  # bluetooth pairings
      "/var/lib/tailscale"  # tailscale node identity at /var/lib/tailscale/tailscaled.state after first tailnet connection using one-time authKey
      "/var/lib/prometheus/node-exporter-text-files"  # persist btrfs scrub metrics between weekly scrubs
    ];

    # user-level persistence
    users.chris = {
      directories = [
        { directory = ".local/share/keyrings"; mode = "0700"; } # gnome keyring secrets like nextcloud client login, etc.
        { directory = ".config/age"; mode = "0700"; } # user age key for home-manager SOPS
        "nextcloud-client" # local nextcloud directory
        ".mozilla" # firefox profiles
        ".config/Element" # matrix e2e keys
        ".config/Nextcloud" # nextcloud sync state
        ".config/VSCodium" # codium editor state
      ];
    };

  };

  # create parent directories with correct permissions
  systemd.tmpfiles.rules = [
    "d /persist/home/chris 0700 chris users -" # tmpfiles ensures directory exists before impermanence tooling bind-mounts /persist/home/{user}/.config/age directory
    "d /persist/etc/age 0755 root root -" # since early bind mounting /etc/age manually (i.e. not using impermanence tooling bind mounts) due to sops needing age keys for user creation prior to impermanence bind mounts (deploy script should create this, but tmpfiles as fallback)
  ];
  
}