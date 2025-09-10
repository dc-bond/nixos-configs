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
    };
  };

  users.users.${configVars.userName}.extraGroups = [ "docker" ];

}
