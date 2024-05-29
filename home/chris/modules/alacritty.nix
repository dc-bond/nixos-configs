{ pkgs, ... }: 

{

# alacritty terminal
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "SauceCodePro NF";
          style = "Regular";
        };
        bold = {
          family = "SauceCodePro NF";
          style = "Bold";
        };
        italic = {
          family = "SauceCodePro NF";
          style = "Italic";
        };
        bold_italic = {
          family = "SauceCodePro NF";
          style = "Bold Italic";
        };
        size = 8.0;
      };
    };
  };

}