{ pkgs,
  config,
  ... 
}:

{

  #systemd.services.create-stirling-pdf-network = with config.virtualisation.oci-containers; {
  #  serviceConfig.Type = "oneshot";
  #  #wantedBy = [ "podman-stirling-pdf.service" ];
  #  script = ''
  #    ${pkgs.podman}/bin/podman network exists stirling || ${pkgs.podman}/bin/podman network create stirling 
  #    '';
  #};

  systemd.services.pod-stirling-pdf = {
    description = "start podman 'stirling-pdf' pod";
    wants = ["network-online.target"];
    after = ["network-online.target"];
    requiredBy = ["podman-stirling-pdf.service"];
    unitConfig = {
      RequiresMountsFor = "/run/containers";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "-${pkgs.podman}/bin/podman pod create -p 16237:8080 stirling-pdf";
    };
  };

  virtualisation.oci-containers.containers = {
    stirling-pdf = {
      image = "docker.io/frooodle/s-pdf:0.18.1";
      autoStart = true;
      #ports = [
      #  "16237:8080/tcp"
      #];
      extraOptions = [
        "--pod=stirling-pdf"
      ];
      log-driver = "journald";
    };
  };

}