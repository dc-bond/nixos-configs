{ config, lib, pkgs, ... }: 

{
  home.packages = with pkgs; [
    yubikey-personalization # tool required to make changes to yubikeys
    yubikey-manager
    yubioath-desktop # desktop tool to setup OTP codes on yubikey
  ];
  
  #services.udev.packages = with pkgs; [ # goes in configuration.nix?
  #  yubikey-personalization
  #];
}

# NOTE IF USING MULTIPLE YUBIKEYS WITH SAME PRIVATE KEYS LOADED USE FOLLOWING TO SWITCH TO NEW YUBIKEY
# 'killall gpg-agent'
# 'rm -r ~/.gnupg/private-keys-v1.d/'
# 'gpg --card-status'