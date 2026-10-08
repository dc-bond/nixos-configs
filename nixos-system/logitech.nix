{
  pkgs,
  ...
}:

# hid++ control of logitech peripherals. hardware.logitech.wireless.enable installs solaar's
# udev rules, which tag logitech hidraw nodes (usb receivers and bluetooth 0005:046D:*) with
# uaccess so the active seat's user can open them; without it /dev/hidraw* is root-only and
# solaar reports "No supported device found"
{

  hardware.logitech.wireless.enable = true;

  environment.systemPackages = with pkgs; [
    solaar # cli used by the hyprland input-switch binds, e.g. 'solaar config <device> change-host <n>'
  ];

}
