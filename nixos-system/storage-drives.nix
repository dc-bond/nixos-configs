{ 
  config, 
  configVars, 
  lib, 
  ... 
}:

let
  hostData = configVars.hosts.${config.networking.hostName};
in

{

  fileSystems = lib.mapAttrs' (name: drive: {
    name = drive.mountPoint;
    value = {
      device = "/dev/disk/by-uuid/${drive.uuid}";
      fsType = drive.fsType;
      options = [ "defaults" ];
    };
  }) hostData.hardware.storageDrives;
  
}