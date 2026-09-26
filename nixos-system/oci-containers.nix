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
      storageDriver = "overlay2"; # current docker recommendation, does not create nested btrfs subvolumes
      daemon.settings = {
        log-driver = "journald"; # log rotation/retention handled by journald config in foundation.nix
        dns = [ 
          "1.1.1.1" 
          "9.9.9.9" 
        ]; # use public dns for container pulls (skirt circular dependency on pihole/unbound)
      };
      #listenOptions = lib.mkIf (hostData.networking.tailscaleIp != null) [
      #  "/var/run/docker.sock"
      #  "${hostData.networking.tailscaleIp}:2375" # see systemd dependency below
      #];
    };
  };

  # restart policy for every container, in one place rather than per module.
  # on-failure leaves a cleanly-exited container down, so a deliberate
  # `docker stop` is not fought by systemd; mkForce because the module sets
  # Restart at normal priority. the backoff walks 100ms -> 1m over 9 steps so a
  # container whose dependency is not up yet stops hammering; the module sets
  # none of the three, so they need no override.
  systemd.services = lib.mapAttrs' (name: _:
    lib.nameValuePair "${config.virtualisation.oci-containers.backend}-${name}" {
      serviceConfig = {
        Restart = lib.mkForce "on-failure";
        RestartSec = "100ms";
        RestartSteps = 9;
        RestartMaxDelaySec = "1m";
      };
    }
  ) config.virtualisation.oci-containers.containers;

  ## ensure docker.socket waits for tailscale interface when binding to tailscale ipv4
  #systemd.sockets.docker = lib.mkIf (hostData.networking.tailscaleIp != null) {
  #  after = [ "tailscaled-autoconnect.service" ];
  #  # Note: using After= without Requires= because tailscaled-autoconnect is oneshot and exits
  #  # We just need to ensure ordering, not create a dependency
  #};

}