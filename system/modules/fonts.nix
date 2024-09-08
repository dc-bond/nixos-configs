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
      (pkgs.nerdfonts.override { # override installing the entire nerdfonts repo and only install specified fonts from the nerdfonts repo
        fonts = [
          "SourceCodePro"
          "DroidSansMono"
          "FiraCode"
        ];
      })
    ];
  };

}