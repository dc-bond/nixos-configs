{ 
  inputs, 
  config,
  lib,
  configLib,
  pkgs, 
  osConfig,
  ... 
}: 

let
  wallpaperDir = pkgs.runCommand "wallpapers" {} ''
    mkdir -p $out
    cp -r ${inputs.self}/wallpaper/* $out/
  '';
in

{

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 0;
        hide_cursor = true;
        no_fade_in = false;
        no_fade_out = false;
      };
      background = [
        {
          path = "${wallpaperDir}/wallpaper-92.jpg";
          blur_passes = 3;
          contrast = 1;
          brightness = 0.5;
          vibrancy = 0.2;
          vibrancy_darkness = 0.2;
        }
      ];
      input-field = [
        {
          monitor = "";
          size = "350, 60";
          outline_thickness = 2;
          dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.35; # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = true;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(0, 255, 34, 0.2)";
          fade_on_empty = false;
          rounding = -1;
          check_color = "rgb(204, 136, 34)";
          placeholder_text = "<b><span foreground='##cdd6f4'>AUTHENTICATION REQUIRED</span></b>";
          hide_input = false;
          position = "0, -200";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

}