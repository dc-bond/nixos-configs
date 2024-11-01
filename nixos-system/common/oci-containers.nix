{ pkgs, 
  lib, 
  ... 
}:

{

  #environment.systemPackages = with pkgs; [
  #  #dive # look into docker image layers
  #  #podman-tui # status of containers in the terminal
  #  #podman-compose # start group of containers for dev
  #];

  virtualisation = {
    containers.enable = true;
    oci-containers.backend = "docker";
    docker = {
      enable = true;
      storageDriver = "btrfs";
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
      #autoPrune.enable = true;
      #defaultNetwork.settings = {
      #  dns_enabled = true;
      #};
    };
  };

  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  #networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

}
