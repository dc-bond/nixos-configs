{ pkgs, ... }: 

{

# alacritty terminal
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "SauceCodePro NF";
          #family = "BlexMono NF";
          style = "Regular";
        };
        bold = {
          family = "SauceCodePro NF";
          #family = "BlexMono NF";
          style = "Bold";
        };
        italic = {
          family = "SauceCodePro NF";
          #family = "BlexMono NF";
          style = "Italic";
        };
        bold_italic = {
          family = "SauceCodePro NF";
          #family = "BlexMono NF";
          style = "Bold Italic";
        };
        size = 11.0;
      };
    };
  };

}