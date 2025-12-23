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
      package = inputs.nixpkgs-docker-pinned.legacyPackages.${pkgs.stdenv.hostPlatform.system}.docker;
      autoPrune.enable = true;
      storageDriver = "btrfs"; # support for btrfs
    };
  };

}