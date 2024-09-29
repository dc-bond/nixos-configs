{ 
  inputs, 
  outputs, 
  lib, 
  config, 
  pkgs, 
  ... 
}: 

{
  
  imports = [
    #./disk-config.nix
    ./hardware-configuration.nix
    ../../nixos-system/common/audio.nix
    ../../nixos-system/common/boot.nix
    ../../nixos-system/common/zsh.nix
    ../../nixos-system/common/nixpkgs.nix
    ../../nixos-system/common/fonts.nix
    ../../nixos-system/common/yubikey.nix
    ../../nixos-system/common/thunar.nix
    ../../nixos-system/common/hyprland.nix
    ../../nixos-system/common/printing.nix
    ../../nixos-system/host-specific/thinkpad/login.nix
    ../../nixos-system/host-specific/thinkpad/users.nix
    ../../nixos-system/host-specific/thinkpad/keyring.nix
    ../../nixos-system/host-specific/thinkpad/sshd.nix
    ../../nixos-system/host-specific/thinkpad/sops.nix
    ../../nixos-system/host-specific/thinkpad/bluetooth.nix
    ../../nixos-system/host-specific/thinkpad/networking.nix
    ../../nixos-system/host-specific/thinkpad/wireguard.nix
  ];

# system-wide packages installed (that aren't installed via their own program modules enabled below)
  environment.systemPackages = with pkgs; [
    (import ../../scripts/common/hello-world.nix { inherit pkgs config; })
    (import ../../scripts/common/thinkpadDeploy.nix { inherit pkgs config; })
    (import ../../scripts/common/vm1Deploy.nix { inherit pkgs config; })
    (import ../../scripts/host-specific/thinkpad/rebuild.nix { inherit pkgs config; })
    age # encryption tool
    sops # secrets management tool that can use different types of encryption (e.g. age, pgp, etc.)
    wget # download tool
    brightnessctl # screen brightness application
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
    ddcutil # query and change monitor settings using DDC/CI and USB
    i2c-tools # hardware interface tools required by ddcutil
    nvd # package version diff info for nix build operations
    nix-tree # table view of package dependencies
    ethtool # network tools
    unzip # utility to unzip directories
  ];

# enable i2c kernel module for ddcutil functionality
  hardware.i2c.enable = true;

# set timezone & locale
  time.timeZone = "America/New_York"; # set timezone
  i18n.defaultLocale = "en_US.UTF-8";

# login/cli terminal settings
  console = {
    earlySetup = true;
    font = "Lat2-Terminus16";
    #font = "${pkgs.source-code-pro}/share/consolefonts/???.gz"; # need to fix
    #packages = with pkgs; [ source-code-pro ];
    keyMap = "us";
  };

  services.logind.lidSwitch = "ignore"; # disable suspend on laptop lid close

# set systemd file limit
  systemd.extraConfig = "DefaultLimitNOFILE=2048"; # defaults to 1024 if unset

# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}