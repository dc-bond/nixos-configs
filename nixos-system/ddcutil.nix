{ 
  pkgs, 
  ... 
}: 

# ddc/ci monitor control. the kernel exposes each video-cable i2c bus as /dev/i2c-N;
# hardware.i2c.enable loads the i2c-dev module, creates the "i2c" group and writes the udev
# rule granting that group 660 on those nodes — users.nix then adds every host user to the
# group, keyed off this same option. ddcutil opens the device directly, so i2c-tools is not
# a dependency, just the by-hand diagnostic ('i2cdetect -l') for when ddc isn't working
{

  hardware.i2c.enable = true;

  environment.systemPackages = with pkgs; [
    ddcutil # query and change monitor settings via ddc/ci
    i2c-tools # inspect the underlying i2c buses when ddcutil can't reach a monitor
  ];

}
