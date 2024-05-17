{
  inputs,
  outputs, # if using home-manager as module?
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    #./system-modules/yubikey-gpg.nix
    inputs.home-manager.nixosModules.home-manager # import home-manager module
  ];

  nixpkgs = {
    overlays = [
    ];
    config = {
      allowUnfree = true;
    };
  };

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      flake-registry = "";
      nix-path = config.nix.nixPath;
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  boot.loader.systemd-boot.enable = true; # use systemd-boot EFI boot loader
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl = { "vm.swappiness" = 30;};
  networking.hostName = "thinkpad";

  environment.systemPackages = with pkgs; [ # search system packages with 'nix search [package]'
    #wget
    neovim
    git # installed system-wide to allow ansible root user to clone repo on first install
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
  ];

  users.users = {
    chris = {
      initialPassword = "changeme";
      extraGroups = ["wheel"];
      isNormalUser = true;
      shell = pkgs.zsh; # user-specific z-shell configs in home.nix
      openssh.authorizedKeys.keys = [ 
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDJZBJOhg+DeRoH1UljG6FniW66qtYVmJNYtreg54WL3 chris@dcbond.com"
        ];
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      chris = import ../home-manager/home.nix;
    };
  };

  services.openssh.enable = true; # enable openssh service
  services.openssh.ports = [
    28764
  ];
  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
    KbdInteractiveAuthentication = false;
  };

  time.timeZone = "America/New_York"; # set timezone

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    #keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  programs.mtr.enable = true;

  programs.zsh.enable = true; # z-shell enabled system-wide to source necessary files for users
  environment.pathsToLink = [ "/share/zsh" ]; # to enable z-shell completion for system packages like systemd

  system.stateVersion = "23.11"; # first install nix version pin for maintaining backward compatibility with application data - do not revise

}
