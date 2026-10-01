{ 
  pkgs, 
  ... 
}: 

{

  environment.systemPackages = with pkgs; [
    yubikey-manager # provides 'ykman' cli tool to manage settings on yubikey
    pcsclite # smartcard reader tool
    libfido2 # provides library functionality for FIDO 2.0, including communication with a device over USB - required for websites to interface with the yubikey
  ];

# enable smartcard reader tool
  services.pcscd.enable = true;

# pcsc-lite's polkit policy admits only clients in an active login session. scdaemon (disable-ccid, so it goes
# through pcscd) runs under gpg-agent.service in user@.service, outside the session, so wheel is granted explicitly
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