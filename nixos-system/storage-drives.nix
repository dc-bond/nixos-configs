{
  config,
  configVars,
  lib,
  ...
}:

{

  fileSystems = lib.mapAttrs' (name: drive: {
    name = drive.mountPoint;
    value = {
      device = "/dev/disk/by-uuid/${drive.uuid}";
      fsType = drive.fsType;
      options = [ "defaults" ];
    };
  }) configVars.hosts.${config.networking.hostName}.hardware.storageDrives;
  
}