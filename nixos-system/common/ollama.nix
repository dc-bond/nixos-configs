{ 
  pkgs,
  lib,
  config, 
  ... 
}: 

{

  services.ollama = {
    enable = true;
    user = "ollama";
    port = 11438;
    host = "0.0.0.0";
    openFirewall = true;
    acceleration = "cuda";
    loadModels = [ "mistral" ];
  };

}