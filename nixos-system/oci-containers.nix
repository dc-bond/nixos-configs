{
  pkgs,
  lib,
  config,
  configVars,
  ...
}:

{

  virtualisation = {
    oci-containers.backend = "docker";
    docker = {
      enable = true;
      autoPrune.enable = true;
      storageDriver = "btrfs"; # support for btrfs
    };
  };

}