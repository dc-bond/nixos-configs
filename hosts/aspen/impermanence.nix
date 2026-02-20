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
    options = [ "defaults" "size=4G" "mode=755" ];
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

    users.chris.directories = [
      { directory = ".config/age"; mode = "0700"; }  # user age key for potential future home-manager sops secrets
    ];

    files = [
      "/etc/machine-id"  # systemd machine identity (prevents new journal directories on each boot)
    ];

    directories = [

      # infrastructure
      "/var/lib/nixos"                               # UID/GID mappings to prevent permissions issues on reboot
      "/var/lib/tailscale"                           # tailscale node identity
      "/var/lib/prometheus/node-exporter-text-files" # persist btrfs scrub metrics between weekly scrubs

      # databases
      "/var/lib/postgresql"                          # nextcloud, hass, lldap databases
      "/var/lib/mysql"                               # photoprism database
      "/var/backup/postgresql"                       # postgresql dump files (postgresqlBackup)
      "/var/backup/mysql"                            # mysql dump files (mysqlBackup)

      # application state - native nixos services
      "/var/lib/traefik"                             # ACME certificates
      "/var/lib/nextcloud"                           # nextcloud app state and config
      "/var/lib/redis-nextcloud"                     # nextcloud redis cache
      "/var/lib/hass"                                # home assistant config, automations
      "/var/lib/mosquitto"                           # mqtt broker state
      "/var/lib/private/photoprism"                  # photoprism state (DynamicUser service)
      "/var/lib/private/lldap"                       # lldap state (DynamicUser service)
      "/var/lib/authelia-dcbond"                     # authelia sqlite db, webauthn keys, logs
      "/var/lib/redis-authelia-dcbond"               # authelia session cache
      "/var/lib/calibre-web"                         # calibre-web database
      #"/var/lib/ollama"                              # ollama downloaded models

      # docker - full data root persisted (image layers + all named volumes)
      { directory = "/var/lib/docker"; mode = "0710"; } # docker requires specific permissions on data root

      # logs
      "/var/log/journal"   # persistent system logs across reboots (debugging)
      "/var/log/traefik"   # read by crowdsec for ban decisions

    ];

  };

  # create parent directories with correct permissions
  systemd.tmpfiles.rules = [
    "d /persist/home/chris 0700 chris users -" # tmpfiles ensures directory exists before impermanence tooling bind-mounts /persist/home/{user}/.config/age directory
    "d /persist/etc/age 0755 root root -" # since early bind mounting /etc/age manually (i.e. not using impermanence tooling bind mounts) due to sops needing age keys for user creation prior to impermanence bind mounts (deploy script should create this, but tmpfiles as fallback)
  ];

}
