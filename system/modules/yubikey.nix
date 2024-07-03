{ pkgs, ... }: 

{

# system packages
  environment.systemPackages = with pkgs; [
    yubikey-personalization # tool required to make changes to yubikeys
    yubikey-manager
    yubioath-flutter # gui authenticator app for yubikeys
    pcsclite # smartcard reader tool
    #pcscliteWithPolkit # smartcard reader tool
  ];

# enable smartcard reader tool
  services.pcscd.enable = true;

# enable udev rules for yubikey
  hardware.gpgSmartcards.enable = true;

# nixos pcsclite packages don't include user group to access card when polkit enabled (automatically with hyprland) so workaround to grant access - https://github.com/NixOS/nixpkgs/issues/121121
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.debian.pcsc-lite.access_card" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
    polkit.addRule(function(action, subject) {
      if (action.id == "org.debian.pcsc-lite.access_pcsc" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

# udev package for yubikey
  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];
  
}

# NOTE IF USING MULTIPLE YUBIKEYS WITH SAME PRIVATE KEYS LOADED USE FOLLOWING TO SWITCH TO NEW YUBIKEY
# 'killall gpg-agent'
# 'rm -r ~/.gnupg/private-keys-v1.d/'
# 'gpg --card-status'