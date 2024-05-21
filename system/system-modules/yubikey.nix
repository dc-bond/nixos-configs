{ config, lib, pkgs, ... }: 

{

# system packages
  environment.systemPackages = with pkgs; [
    yubikey-personalization # tool required to make changes to yubikeys
    yubikey-manager
    yubioath-desktop # desktop tool to setup OTP codes on yubikey
    pcsclite # smartcard reader tool
  ];

# enable smartcard reader tool
  services.pcscd.enable = true;

# udev package for yubikey
  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];
  
}

# NOTE IF USING MULTIPLE YUBIKEYS WITH SAME PRIVATE KEYS LOADED USE FOLLOWING TO SWITCH TO NEW YUBIKEY
# 'killall gpg-agent'
# 'rm -r ~/.gnupg/private-keys-v1.d/'
# 'gpg --card-status'