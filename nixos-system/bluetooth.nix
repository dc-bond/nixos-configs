{
  pkgs,
  ...
}:

{

  hardware.bluetooth = {
    enable = true; # also installs bluez-utils to provide bluetoothctl terminal application
    powerOnBoot = true;
    settings = {
      General = {
        FastConnectable = true; # faster reconnection for paired devices (uses more power)
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # disable USB autosuspend for bluetooth adapters - prevents sleep-induced reconnection delays
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="e0", ATTR{bInterfaceSubClass}=="01", TEST=="power/control", ATTR{power/control}="on"
  '';

  #services.blueman.enable = true; # gui application

}