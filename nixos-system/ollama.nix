{ 
  pkgs,
  lib,
  config, 
  ... 
}: 

{

  nixpkgs.config.packageOverrides = pkgs: {
    ollama = pkgs.ollama.override {
      cudaArches = [ "61" ]; # ensure ollama builds with cuda 6.1 for GTX 1060
    };
  };

  services.ollama = {
    enable = true;
    user = "ollama";
    port = 11434;
    host = "0.0.0.0";
    openFirewall = true;
    acceleration = "cuda";
    loadModels = [ "mistral" ];
  };

}