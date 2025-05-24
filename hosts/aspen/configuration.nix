{ 
  inputs, 
  outputs, 
  lib, 
  configLib,
  config, 
  pkgs, 
  ... 
}: 

{

  options.drives = {
    storageDrive1 = lib.mkOption {
      type = lib.types.path;
      default = "/storage/WD-WCC7K4RU947F";
      description = "path to storage drive 1";
    };
  };

  config = {

    fileSystems."${config.drives.storageDrive1}" = {
      device = "/dev/disk/by-uuid/2dbedc67-9a6b-477f-a3b4-75116994d1cb";
      fsType = "ext4"; 
      options = [ "defaults" ];
    };

    environment.systemPackages = with pkgs; [
      wget # download tool
      usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
      nvd # package version diff info for nix build operations
      rsync # sync tool
      git # git
      dig # dns lookup tool
      eza # modern replacement for 'ls'
      pfetch # system info displayed on shell startup
      btop # system monitor
      nmap # network scanning
      #(import (configLib.relativeToRoot "scripts/get-pass-repo.nix") { inherit pkgs config; })
      #age # encryption tool
      #mkpasswd # password hashing tool
      #dig # dns lookup tool
      #sops # secrets management tool that can use different types of encryption (e.g. age, pgp, etc.)
      #wget # download tool
      #rsync # sync tool
      #usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
      #nvd # package version diff info for nix build operations
      #nix-tree # table view of package dependencies
      #ethtool # network tools
      #inetutils # more network tools like telnet
      #unzip # utility to unzip directories
      #git # git
      #eza # modern replacement for 'ls'
      #pfetch # system info displayed on shell startup
      #btop # system monitor
      #nmap # network scanning
      #ddcutil # query and change monitor settings using DDC/CI and USB
      #i2c-tools # hardware interface tools required by ddcutil
      #libreoffice-still # office suite
      #element-desktop # matrix chat app
      #hollywood # fill terminal with melodramatic technobabble
      #cool-retro-term # retro terminal
      #imagemagick # photo tool
      #ffmpeg-full # video tool
    ];

    #hardware.i2c.enable = true; # enable i2c kernel module for ddcutil functionality
    
    # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
    system.stateVersion = "24.11";

  };

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      
      "hosts/aspen/disk-config-btrfs.nix"
      "hosts/aspen/hardware-configuration.nix"
      #"nixos-system/common/audio.nix"
      "nixos-system/common/boot.nix"
      "nixos-system/common/zsh.nix"
      #"nixos-system/common/yubikey.nix"
      "nixos-system/common/misc.nix"
      "nixos-system/common/nixpkgs.nix"
      "nixos-system/common/cloud-backups.nix"
      "nixos-system/common/sops.nix"
      #"nixos-system/common/bluetooth.nix"
      "nixos-system/common/nvidia.nix"

      #"nixos-system/common/keyring.nix"
      #"nixos-system/common/login.nix"
      #"nixos-system/common/thunar.nix"
      #"nixos-system/common/hyprland.nix"
      #"nixos-system/common/printing.nix"
      #"nixos-system/common/fonts.nix"

      "nixos-system/host-specific/aspen/borg-backups.nix"
      "nixos-system/host-specific/aspen/networking.nix"
      "nixos-system/host-specific/aspen/sshd.nix"
      "nixos-system/host-specific/aspen/tailscale.nix"
      "nixos-system/host-specific/aspen/users.nix"
      #"nixos-system/host-specific/aspen/journal2gelf.nix"
      
      "nixos-system/common/traefik.nix"
      "nixos-system/common/postgresql.nix"
      "nixos-system/common/mysql.nix"
      "nixos-system/common/photoprism.nix" # requires mysql.nix
      #"nixos-system/common/lldap.nix" # requires postgresql.nix
      #"nixos-system/common/mosquitto.nix"
      #"nixos-system/common/uptime-kuma.nix"
      #"nixos-system/common/graylog.nix"
      #"nixos-system/common/kasmweb.nix"
      #"nixos-system/common/writefreely.nix" # requires mysql.nix
      #"nixos-system/common/nextcloud.nix" # requires postgresql.nix
      #"nixos-system/common/home-assistant.nix" # requires postgresql.nix, mosquitto.nix
      #"nixos-system/common/authelia-dcbond.nix" # requires lldap.nix
      #"nixos-system/common/stirling-pdf.nix"
      #"nixos-system/common/roundcube.nix" # requires postgresl.nix
      #"nixos-system/common/matrix.nix" # requires postgresql.nix
      #"nixos-system/common/privatebin.nix"
      #"nixos-system/common/dcbond-root.nix"
      #"nixos-system/common/unifi-controller.nix" # compile problems with mongodb
      "nixos-system/common/oci-containers.nix"
      "nixos-system/common/oci-fava.nix"
      "nixos-system/common/oci-media-server.nix" # requires nvidia.nix
      "nixos-system/common/oci-frigate.nix" # requires nvidia.nix
      #"nixos-system/common/oci-unifi-controller.nix"
      #"nixos-system/common/oci-pihole.nix"
      #"nixos-system/common/oci-actual.nix"
      #"nixos-system/common/oci-zwavejs.nix"
      #"nixos-system/common/oci-chromium.nix"
      #"nixos-system/common/oci-searxng.nix"
      #"nixos-system/common/oci-wordpress-dcbond.nix"
      #"nixos-system/common/oci-recipesage.nix"
      #"nixos-system/common/oci-librechat.nix"

      "scripts/rebuild/rebuild-local-aspen.nix"
      "scripts/rebuild/rebuild-remote-thinkpad.nix"
      "scripts/rebuild/rebuild-remote-cypress.nix"
      "scripts/deploy/deploy-thinkpad.nix"
      "scripts/deploy/deploy-cypress.nix"
      "scripts/photo-renumber.nix"
      "scripts/media-transfer.nix"
      "scripts/backup-recovery/recover-family-media.nix"
      #"scripts/backup-recovery/recover-email.nix"
      #"scripts/backup-recovery/recover-traefik.nix"
      #"scripts/backup-recovery/recover-homeassistant.nix"
      #"scripts/backup-recovery/recover-matrix.nix"
      #"scripts/backup-recovery/recover-photoprism.nix"
      #"scripts/backup-recovery/recover-nextcloud.nix"
      #"scripts/backup-recovery/recover-uptime-kuma.nix"
      #"scripts/backup-recovery/recover-zwavejs.nix"
      #"scripts/backup-recovery/recover-media-server.nix"
      #"scripts/backup-recovery/recover-lldap.nix"
      #"scripts/backup-recovery/recover-searxng.nix"
      #"scripts/backup-recovery/recover-chromium.nix"
      #"scripts/backup-recovery/recover-actual.nix"
      "scripts/backup-recovery/recover-pihole.nix"
      #"scripts/backup-recovery/recover-unifi-controller.nix"
      #"scripts/backup-recovery/recover-recipesage.nix"
      #"scripts/backup-recovery/recover-roundcube.nix"
    ])
  ];

}