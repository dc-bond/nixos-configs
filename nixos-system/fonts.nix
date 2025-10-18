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
      #nerd-fonts.droid-sans-mono
      #(pkgs.nerdfonts.override { # override installing the entire nerdfonts repo and only install specified fonts from the nerdfonts repo
      #  fonts = [
      #    "SourceCodePro"
      #    "DroidSansMono"
      #    "FiraCode"
      #  ];
      #})
    ];
  };

}