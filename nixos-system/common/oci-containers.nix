{ pkgs, 
  lib, 
  ... 
}:

{

  environment.systemPackages = with pkgs; [
    podman-tui # status of containers in the terminal
    #podman-compose # start group of containers for dev
  ];

  virtualisation = {
    containers.enable = true;
    oci-containers.backend = "podman";
    podman = {
      enable = true;
      autoPrune.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  #networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

}
