{ 
  configVars, 
  ... 
}:

{

  virtualisation = {
    oci-containers.backend = "docker";
    docker = {
      enable = true;
      storageDriver = "btrfs"; # support for btrfs
      setSocketVariable = true; # run rootless
      daemon.settings = {
        data-root = "/home/${configVars.username}/oci-containers/";
      };
    };
  };

  systemd.services.init-docker-network-backend = {
    description = "create network bridge backend for oci docker containers";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      check=$(${pkgs.docker}/bin/docker network ls | grep "backend" || true)
      if [ -z "$check" ];
        then ${pkgs.docker}/bin/docker network create --subnet 172.21.2.0/25 --driver bridge --scope local --attachable backend 
        else echo "docker network bridge backend already exists"
      fi
    '';
  };

}
