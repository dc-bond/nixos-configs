{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  boot.loader.systemd-boot.enable = true; # use systemd-boot EFI boot loader
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl = { "vm.swappiness" = 30;};

  networking.hostName = "t490"; # define hostname
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  time.timeZone = "America/New_York"; # set timezone

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    #keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  users.users.chris = {
    isNormalUser = true;
    initialPassword = "changeme"; # disposable password to allow initial user login, change by running 'passwd' in terminal immediately following first login
    home = "/home/chris";
    extraGroups = [ "wheel" ]; # enable ‘sudo’
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOOuXAgAXvwd1oKv7tZAR/jdeyXcfj41xb6hrMdP04G7 chris@dcbond.com" 
      ];
  };

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  environment.systemPackages = with pkgs; [ # search system packages with 'nix search [package]'
    wget
    neovim
    git
  ];

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  #programs.hyprland.enable = true;

  services.openssh.enable = true; # enable openssh service
  services.openssh.ports = [
    28764
  ];
  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
    KbdInteractiveAuthentication = false;
  };

  services.xserver.libinput.enable = true; # enable touchpad support
  # services.printing.enable = true; # enable cups print server
  # services.xserver.enable = true; # enable X11 window manager
  # services.xserver.xkb.layout = "us"; # keymap for X11
  # services.xserver.xkb.options = "eurosign:e,caps:escape"; # keymap for X11

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.copySystemConfiguration = true; # copy configuration.nix from /run/current-system/configuration.nix in case of accidental deletion
  system.stateVersion = "23.11"; # first install nix version pin for maintaining backward compatibility with application data - do not revise

}