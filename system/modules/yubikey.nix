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