{ 
  pkgs,
  configVars, 
  ... 
}:

{

  virtualisation = {
    oci-containers.backend = "docker";
    docker = {
      enable = true;
      autoPrune.enable = true;
      storageDriver = "btrfs"; # support for btrfs
      rootless = {
        enable = true; # run rootless
        setSocketVariable = true; # set DOCKER_HOST variable to the rootless docker instance for normal users by default
      };
      #daemon.settings = {
      #  userland-proxy = false;
      #  experimental = true;
      #  metrics-addr = "0.0.0.0:9323";
      #  ipv6 = false;
      #  #fixed-cidr-v6 = "fd00::/80";
      #};
    };
  };

  users.users.${configVars.userName}.extraGroups = [ "docker" ];

}
