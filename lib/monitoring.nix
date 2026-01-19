{ lib, ... }:

{
  options.monitoring = {
    endpoints = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        List of HTTPS endpoints to monitor with blackbox exporter.
        Each service module can append its public URLs here, and they will be
        automatically collected by monitoring-server.nix for probing.
      '';
      example = [
        "https://cloud.example.com"
        "https://photos.example.com"
      ];
    };
  };
}
