{ 
  pkgs, 
  config,
  ... 
}: 

{

  services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;
  };

  environment.systemPackages = with pkgs; [
    # iOS support
    libimobiledevice
    ifuse
    # android support
    jmtpfs
    android-tools
  ];

  systemd.tmpfiles.rules = [
    "d /mnt/iphone 0755 chris users -"
    "d /mnt/android 0755 chris users -"
  ];

  programs.zsh.shellAliases = {
    mount-iphone = "ifuse /mnt/iphone";
    unmount-iphone = "fusermount -u /mnt/iphone";
    mount-android = "jmtpfs /mnt/android";
    unmount-android = "fusermount -u /mnt/android";
  };

}