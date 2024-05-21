{ config, lib, pkgs, ... }: 

{

# hyprland
  programs.hyprland.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  #security.polkit.enable = true;
  #hardware.opengl.enable = true; # when using QEMU KVM

}