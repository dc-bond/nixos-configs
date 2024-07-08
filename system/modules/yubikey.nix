{ pkgs, ... }: 

{

# system packages
  environment.systemPackages = with pkgs; [
    yubikey-manager # provides ykman cli tool to manage settings on yubikey
    yubioath-flutter # gui authenticator app/tool for yubikeys
    pcsclite # smartcard reader tool
    libfido2 # provides library functionality for FIDO 2.0, including communication with a device over USB
  ];

# enable smartcard reader tool
  services.pcscd.enable = true;

## enable udev rules for yubikey
#  hardware.gpgSmartcards.enable = true;

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

}

# NOTE IF USING MULTIPLE YUBIKEYS WITH SAME PRIVATE KEYS LOADED USE FOLLOWING TO SWITCH TO NEW YUBIKEY
# 'killall gpg-agent'
# 'rm -r ~/.gnupg/private-keys-v1.d/'
# 'gpg --card-status'