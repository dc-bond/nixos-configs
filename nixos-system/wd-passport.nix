{ 
  config, 
  lib, 
  pkgs, 
  ... 
}:

{

  options.hardware.wdPassport = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable WD My Passport 260D external drive auto-mounting";
    };
  };

  config = lib.mkIf config.hardware.wdPassport.enable {

    # external USB drive: WD My Passport 260D
    # auto-mounts to /storage-ext4-external when plugged in via udev (no boot dependency)
    # mount point /storage-ext4-external created by systemd-tmpfiles below
    # portable between hosts - plug into any host with this module imported

    services.udev.extraRules = ''
      # auto-mount WD My Passport 260D to /storage-ext4-external when plugged in
      SUBSYSTEM=="block", ENV{ID_FS_UUID}=="025cbd65-8476-47ef-a814-c3cd8624d2fc", \
        ACTION=="add", \
        RUN+="${pkgs.systemd}/bin/systemctl start storage-automount.service"
      # auto-unmount when unplugged
      SUBSYSTEM=="block", ENV{ID_FS_UUID}=="025cbd65-8476-47ef-a814-c3cd8624d2fc", \
        ACTION=="remove", \
        RUN+="${pkgs.systemd}/bin/systemctl stop storage-automount.service"
    '';

    systemd.services.storage-automount = {
      description = "Auto-mount WD My Passport 260D to /storage-ext4-external";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.util-linux}/bin/mount -o noatime UUID=025cbd65-8476-47ef-a814-c3cd8624d2fc /storage-ext4-external";
        ExecStop = "${pkgs.util-linux}/bin/umount /storage-ext4-external";
      };
    };

    systemd.tmpfiles.rules = [ "d /storage-ext4-external 0755 root root -" ];  # create /storage-ext4-external mount point

  };

}
