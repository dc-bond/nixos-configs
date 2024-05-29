{ pkgs, ... }: 

{

# alacritty terminal
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          #family = "SauceCodePro NF";
          family = "BlexMono";
          style = "Regular";
        };
        bold = {
          #family = "SauceCodePro NF";
          family = "BlexMono";
          style = "Bold";
        };
        italic = {
          #family = "SauceCodePro NF";
          family = "BlexMono";
          style = "Italic";
        };
        bold_italic = {
          #family = "SauceCodePro NF";
          family = "BlexMono";
          style = "Bold Italic";
        };
        size = 8.0;
      };
    };
  };

}