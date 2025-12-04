{ 
  pkgs, 
  ... 
}: 

{

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      source-code-pro
      source-sans-pro
      font-awesome
      nerd-fonts.sauce-code-pro
      nerd-fonts.fira-code
    ];
  };

}