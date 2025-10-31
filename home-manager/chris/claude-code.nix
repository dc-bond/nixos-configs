{ 
  config, 
  pkgs, 
  ... 
}: 

{
  imports = [ inputs.home-manager-unstable.nixosModules.default.programs.claude-code ];

  programs.claude-code = {
    enable = true;
    package = pkgs.unstable.claude-code;
  };
  
}