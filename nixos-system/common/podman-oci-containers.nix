{ pkgs, 
  lib, 
  ... 
}:

{

  environment.systemPackages = with pkgs; [
    podman-tui # status of containers in the terminal
  ];

  virtualisation = {
    oci-containers.backend = "podman";
    podman = {
      enable = true;
      autoPrune.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  #systemd.network = {
  #  networks = {
  #    "20-podman" = {
  #      matchConfig.Name = "podman0";
  #      #networkConfig.DHCP = "ipv4";
  #      linkConfig.RequiredForOnline = "no";
  #    };    
  #  };
  #};

  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  #networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

}
