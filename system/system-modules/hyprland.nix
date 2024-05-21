{ pkgs, ... }: 
#{ pkgs, config, ... }: # for nvidia?

{

# hyprland
  programs.hyprland = {
    enable = true;
    #nvidiaPatches = true;
    #xwayland.enable = true;
  };

# system packages
  environment.systemPackages = with pkgs; [
    #waybar
    #(pkgs.waybar.overrideAttrs (oldAttrs: {
    #  mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    #})
    #)
    #eww-wayland # widgets
    #swww # animated wallpaper for wayland window managers
    #swaylock-effects # wayland screenlock application
    #wlogout # wayland logout application
    #nwg-look # gtk settings manager for wayland
    #rofi-wayland # application launcher
    #pinentry-rofi # use rofi for pinentry
    #rofi-calc # calculator add-on for rofi
    #wlr-randr # wayland display setting tool for external monitors
    #pywal # color theme changer
    #dunst # notification daemon
    #libnotify # library to support notification daemons
    #xfce.xfce4-power-manager # laptop power manager
    ##xdg-desktop-portal-hyprland # allow applications to communicate with window manager
    #grim # wayland screenshot tool
    #slurp # wayland region selector
    #scrot # screenshot tool
    #xfce.thunar # file manager
    ##filelight # disk usage visualizer
    #firefox # web browser
    #mupdf # pdf viewer
    #nextcloud-client # client for connecting to nextcloud servers
    ##ffmpegthumbnailer
    ##nvidia
    #autorandr # automatically select a display configuration based on connected devices
    #ddcutil # query and change monitor settings using DDC/CI and USB
    #brightnessctl # screen brightness application
    ##xorg-xset # tool to set keyboard repeat delay
    #bleachbit # disk cleaner
  ];

# security changes required for compositor
  security = {
    #rtkit.enable = true;
    polkit.enable = true;
  };

## sound
#  sound.enable = true
#  services.pipewire = {
#    enable = true;
#    alsa.enable = true;
#    alsa.support32Bit = true;
#    pulse.enable = true;
#    jack.enable = true;
#  };

## alacritty terminal
#  programs.alacritty = {
#    enable = true;
#    #settings = {
#    #  font = {
#    #    normal = {
#    #      family = "IosevkaTerm Nerd Font";
#    #      style = "Regular";
#    #    };
#    #    bold = {
#    #      family = "IosevkaTerm Nerd Font";
#    #      style = "Bold";
#    #    };
#    #    italic = {
#    #      family = "IosevkaTerm Nerd Font";
#    #      style = "Italic";
#    #    };
#    #    bold_italic = {
#    #      family = "IosevkaTerm Nerd Font";
#    #      style = "Bold Italic";
#    #    };
#    #    size = 16;
#    #  };
#    };

## allow applications to communicate with compositor
#  xdg.portal = {
#    enable = true;
#    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
#  };

## environment
#  environment.sessionVariables = {
#    NIXOS_OZONE_WL = "1";
#    #WLR_NO_HARDWARE_CURSORS = "1"; # if cursor does not appear
#  };

## nvidia-specific settings
#  hardware.opengl = {
#    enable = true;
#    driSupport = true;
#    driSupport32Bit = true;
#  };
#  services.xserver.videoDrivers = ["nvidia"]; # load nvidia driver for xorg and wayland
#  hardware.nvidia = {
#    modesetting.enable = true;
#    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
#    # Enable this if you have graphical corruption issues or application crashes after waking
#    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
#    # of just the bare essentials.
#    powerManagement.enable = false;
#    # Fine-grained power management. Turns off GPU when not in use.
#    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
#    powerManagement.finegrained = false;
#    # Use the NVidia open source kernel module (not to be confused with the
#    # independent third-party "nouveau" open source driver).
#    # Support is limited to the Turing and later architectures. Full list of 
#    # supported GPUs is at: 
#    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
#    # Only available from driver 515.43.04+
#    # Currently alpha-quality/buggy, so false is currently the recommended setting.
#    open = false;
#    nvidiaSettings = true; # enable nvidia settings menu, accessible via 'nvidia-settings'
#    # Optionally, you may need to select the appropriate driver version for your specific GPU.
#    package = config.boot.kernelPackages.nvidiaPackages.stable;
#  };

}