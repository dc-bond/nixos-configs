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
      #sops # secrets management tool that can use different types of encryption (e.g. age, pgp, etc.)
      #imagemagick # photo tool
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
      "nixos-system/common/lldap.nix" # requires postgresql.nix
      "nixos-system/common/mosquitto.nix"
      "nixos-system/common/uptime-kuma.nix"
      "nixos-system/common/calibre.nix"
      #"nixos-system/common/graylog.nix"
      #"nixos-system/common/kasmweb.nix"
      "nixos-system/common/nextcloud.nix" # requires postgresql.nix
      "nixos-system/common/home-assistant.nix" # requires postgresql.nix, mosquitto.nix
      "nixos-system/common/authelia-dcbond.nix" # requires lldap.nix
      "nixos-system/common/stirling-pdf.nix"
      #"nixos-system/common/roundcube.nix" # requires postgresl.nix
      "nixos-system/common/matrix.nix" # requires postgresql.nix
      "nixos-system/common/privatebin.nix"
      "nixos-system/common/dcbond-root.nix"
      #"nixos-system/common/unifi-controller.nix" # compile problems with mongodb
      "nixos-system/common/oci-containers.nix"
      "nixos-system/common/oci-fava.nix"
      "nixos-system/common/oci-media-server.nix" # requires nvidia.nix
      "nixos-system/common/oci-frigate.nix" # requires nvidia.nix
      "nixos-system/common/oci-unifi-controller.nix"
      "nixos-system/common/oci-pihole.nix"
      "nixos-system/common/oci-actual.nix"
      "nixos-system/common/oci-zwavejs.nix"
      "nixos-system/common/oci-chromium.nix"
      "nixos-system/common/oci-searxng.nix"
      #"nixos-system/common/oci-wordpress-dcbond.nix"
      "nixos-system/common/oci-recipesage.nix"
      #"nixos-system/common/oci-librechat.nix"

      "scripts/photo-renumber.nix"
      "scripts/media-transfer.nix"
    ])
  ];

}