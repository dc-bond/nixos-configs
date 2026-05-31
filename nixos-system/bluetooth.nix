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
        # NOTE: LL Privacy (KernelExperimental LE address resolution) was REMOVED 2026-05-31.
        # On this Intel adapter it stalled the post-disconnect passive scan, so BLE reconnects
        # (esp. the MX Anywhere 3S) took longer the more uptime cypress had (instant after reboot,
        # ~9-15s after days). btmon proved the delay was entirely the scan gap before the mouse's
        # advertisement was heard; once heard, connect+encrypt+HID took ~120ms. It resets on reboot
        # because the stall is controller-internal state that accumulates over uptime.
        # Despite the upstream comment claiming it speeds reconnection, it did the opposite here.
        # KernelExperimental = "15c0a148-c273-11ea-b3de-0242ac130004"; # LL privacy
      };
      Policy = {
        AutoEnable = true;
        ReconnectAttempts = 7; # increase from default 3
        ReconnectIntervals = "1,2,4,8,16,32,64"; # backoff intervals in seconds
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