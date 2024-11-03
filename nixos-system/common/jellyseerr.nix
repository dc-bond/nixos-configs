{
  ...
}: 

{

  virtualisation.oci-containers.containers."jellyseerr" = {
    image = "fallenbagel/jellyseerr:2.0.1";
    autoStart = true;
    #volumes = [
    #  "/home/chris/oci-containers/jellyseerr:/app/config"
    #];
    ports = [
      "5055:5055"
    ];
  };

  #networking.firewall.allowedTCPPorts = [
  #  5055
  #];

}