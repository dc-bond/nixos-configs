{ 
  pkgs,
  lib,
  config, 
  ... 
}: 

{

  hardware = {
    graphics.enable = true; # enable opengl
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false; # only needed if issues resuming from sleep/suspend
      powerManagement.finegrained = false; # experimental turns off GPU when not in use, only works on Turing or newer cards
      open = false; # use open source nvidia kernel module, only works on Turning or newer cards and driver 515.43.04+ (GTX1060 is older)
      nvidiaSettings = true; # enable nvidia settings menu accessible via 'nvidia-settings'
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    #nvidia-container-toolkit = { # enable GPU utilization by oci-containers
    #  enable = true;
    #};
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ]; # load nvidia driver for xorg and wayland

  #virtualisation.docker.rootless.daemon.settings.features.cdi = true; # enable GPU utilization by oci-containers

  #boot.kernelParams = [ "nvidia-drm.modeset=1" ];
  
  # Enable GBM (Generic Buffer Manager) for Wayland support
  #environment.variables = {
  #  GBM_BACKEND = "nvidia";
  #  __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  #  WLR_NO_HARDWARE_CURSORS = "1";  # Fix cursor issues in Wayland
  #};

}