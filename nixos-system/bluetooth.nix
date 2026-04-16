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
        ReconnectAttempts = 7; # increase from default 3
        ReconnectIntervals = "1,2,4,8,16,32,64"; # backoff intervals in seconds
        # enable LL privacy for hardware-accelerated address resolution (faster BLE reconnection)
        # https://github.com/bluez/bluez/blob/master/src/main.conf
        KernelExperimental = "15c0a148-c273-11ea-b3de-0242ac130004";
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # disable USB autosuspend and enable wakeup for intel bluetooth adapters (vendor 8087)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", ATTR{power/control}="on", ATTR{power/wakeup}="enabled"
  '';

  # disable btusb autosuspend at kernel module level
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=0
  '';

  #services.blueman.enable = true; # gui application

}