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
    android-udev-rules
  ];

  systemd.tmpfiles.rules = [
    "d /mnt/iphone 0755 chris users -"
    "d /mnt/android 0755 chris users -"
  ];

  # Helper scripts
  #environment.shellAliases = {
  #  mount-iphone = "ifuse /mnt/iphone";
  #  unmount-iphone = "fusermount -u /mnt/iphone";
  #  mount-android = "jmtpfs /mnt/android";
  #  unmount-android = "fusermount -u /mnt/android";
  #};


  #environment.etc."phone-mount/copy-iphone-photos.sh" = {
  #  text = ''
  #    #!/usr/bin/env bash
  #    set -e
  #    
  #    DEST="${config.hostSpecificConfigs.storageDrive1}/samba/media-uploads"
  #    SOURCE="/mnt/iphone/DCIM"
  #    
  #    if [ ! -d "$SOURCE" ]; then
  #      echo "Error: iPhone not mounted or DCIM folder not found"
  #      exit 1
  #    fi
  #    
  #    echo "Copying photos from iPhone to $DEST..."
  #    rsync -av --progress "$SOURCE/" "$DEST/"
  #    
  #    echo ""
  #    echo "Copy complete!"
  #    echo "Files copied to: $DEST"
  #    
  #    # Fix ownership
  #    chown -R chris:users "$DEST"
  #  '';
  #  mode = "0755";
  #};

  #environment.etc."phone-mount/copy-android-photos.sh" = {
  #  text = ''
  #    #!/usr/bin/env bash
  #    set -e
  #    
  #    DEST="${config.hostSpecificConfigs.storageDrive1}/samba/media-uploads"
  #    
  #    # Android has multiple possible locations
  #    for SOURCE in "/mnt/android/DCIM/Camera" "/mnt/android/DCIM" "/mnt/android/Pictures"; do
  #      if [ -d "$SOURCE" ]; then
  #        echo "Found photos at: $SOURCE"
  #        echo "Copying to $DEST..."
  #        rsync -av --progress "$SOURCE/" "$DEST/"
  #        break
  #      fi
  #    done
  #    
  #    if [ ! -d "$SOURCE" ]; then
  #      echo "Error: Android not mounted or photo folder not found"
  #      echo "Available folders:"
  #      ls -la /mnt/android/ 2>/dev/null || echo "Nothing mounted"
  #      exit 1
  #    fi
  #    
  #    echo ""
  #    echo "Copy complete!"
  #    echo "Files copied to: $DEST"
  #    
  #    # Fix ownership
  #    chown -R chris:users "$DEST"
  #  '';
  #  mode = "0755";
  #};

  #environment.etc."phone-mount/unmount-all.sh" = {
  #  text = ''
  #    #!/usr/bin/env bash
  #    
  #    echo "Unmounting all phone mounts..."
  #    
  #    fusermount -u /mnt/iphone 2>/dev/null && echo "iPhone unmounted" || echo "iPhone not mounted"
  #    fusermount -u /mnt/android 2>/dev/null && echo "Android unmounted" || echo "Android not mounted"
  #    
  #    echo "Done!"
  #  '';
  #  mode = "0755";
  #};

}