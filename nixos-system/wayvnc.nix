{
  pkgs,
  ...
}:

{

  programs.wayvnc = {
    enable = true;
    package = pkgs.wayvnc;
  };
  
}
