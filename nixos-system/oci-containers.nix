{
  pkgs,
  lib,
  config,
  configVars,
  ...
}:

let
  hostData = configVars.hosts.${config.networking.hostName};
in

{

  virtualisation = {
    oci-containers.backend = "docker";
    docker = {
      enable = true;
      autoPrune.enable = true;
      storageDriver = "btrfs"; # support for btrfs
      daemon.settings = {
        log-driver = "journald"; # log rotation/retention handled by journald config in foundation.nix
      };
      #listenOptions = lib.mkIf (hostData.networking.tailscaleIp != null) [
      #  "/var/run/docker.sock"
      #  "${hostData.networking.tailscaleIp}:2375" # see systemd dependency below
      #];
    };
  };

  ## ensure docker.socket waits for tailscale interface when binding to tailscale ipv4
  #systemd.sockets.docker = lib.mkIf (hostData.networking.tailscaleIp != null) {
  #  after = [ "tailscaled-autoconnect.service" ];
  #  # Note: using After= without Requires= because tailscaled-autoconnect is oneshot and exits
  #  # We just need to ensure ordering, not create a dependency
  #};

}