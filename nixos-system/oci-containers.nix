{
  pkgs,
  lib,
  config,
  configVars,
  inputs,
  ...
}:

{

  virtualisation = {
    oci-containers.backend = "docker";
    docker = {
      enable = true;
      package = inputs.nixpkgs-docker-pinned.legacyPackages.${pkgs.system}.docker;
      autoPrune.enable = true;
      storageDriver = "btrfs"; # support for btrfs
    };
  };

}