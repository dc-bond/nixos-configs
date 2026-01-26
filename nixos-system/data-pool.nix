{ lib, ... }:

{
  options.dataPool.path = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = "Path to this host's primary data storage pool";
  };
}
