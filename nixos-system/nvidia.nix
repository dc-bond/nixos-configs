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
      nvidiaSettings = false; # enable nvidia settings menu accessible via 'nvidia-settings'
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    nvidia-container-toolkit.enable = true;  # enable GPU utilization by oci-containers
  };

  services.xserver.videoDrivers = [ "nvidia" ]; # load nvidia driver for xorg and wayland

  boot.blacklistedKernelModules = [ "nouveau" ];

  environment.systemPackages = with pkgs; [ 
    mesa-demos
  ];
  
  virtualisation.docker.daemon.settings.features.cdi = true;

}