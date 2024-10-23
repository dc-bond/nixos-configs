{ pkgs, 
  ... 
}:

{

  systemd.services.create-stirling-pdf-network = with config.virtualisation.oci-containers; {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "${backend}-stirling-pdf.service" ];
    script = ''
      ${pkgs.podman}/bin/podman network exists backend || \
      ${pkgs.podman}/bin/podman network create backend 
      '';
  };

  virtualisation.oci-containers.containers = {
    stirling-pdf = {
      image = "docker.io/frooodle/s-pdf:0.18.1";
      autoStart = true;
      ports = [
        "16237:8080/tcp"
      ];
    };
    log-driver = "journald";
    extraOptions = [
      #"--network-alias=stirling-pdf"
      "--network=backend"
    ];
  };

}
