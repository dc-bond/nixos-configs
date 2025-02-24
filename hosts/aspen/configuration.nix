{ 
  inputs, 
  outputs, 
  lib, 
  configLib,
  config, 
  pkgs, 
  ... 
}: 

{

  fileSystems."/media/WD-WCC7K4RU947F" = {
    device = "/dev/disk/by-uuid/2dbedc67-9a6b-477f-a3b4-75116994d1cb";
    fsType = "ext4"; 
    options = [ "defaults" ];
  };

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      
    ])
  ];

  environment.systemPackages = with pkgs; [
    #(import (configLib.relativeToRoot "scripts/restore-backup.nix") { inherit pkgs config; })
    nvd # package version diff info for nix build operations
    btop # system monitor
    nmap # network scanning
    ethtool # network tools
    gzip # compress/decompress tool
  ];
  
# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}