{
  pkgs,
  lib,
  config,
  ...
}:

{

  services.ollama = {
    enable = true;
    port = 11434;
    host = "0.0.0.0";
    openFirewall = true;
    loadModels = [ "mistral" ];
    package = pkgs.ollama-cuda.override {
      cudaArches = [ "61" ]; # GTX 1060 compute capability 6.1 (pascal)
    };
  };

}