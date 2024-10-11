{ 
  pkgs, 
  configLib,
  ... 
}: 

{

  environment.systemPackages = with pkgs; [
    (import (configLib.relativeToRoot "scripts/host-specific/thinkpad/rebuild.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/host-specific/thinkpad/vm1Rebuild.nix") { inherit pkgs config; })
    brightnessctl # screen brightness application
    ddcutil # query and change monitor settings using DDC/CI and USB
    i2c-tools # hardware interface tools required by ddcutil
    libreoffice-still # office suite
    #element-desktop-wayland # matrix chat app
  ];

}