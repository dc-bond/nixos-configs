{ 
  pkgs, 
  ... 
}: 

{

  programs.alacritty = {
    enable = true;
    settings = {
      general.live_config_reload = true;
      cursor = {
        style = {
          shape = "Block";
          blinking = "Off";
        };
        vi_mode_style = {
          shape = "Block";
          blinking = "Off";
        };
      };
      debug = {
        log_level = "DEBUG";
        persistent_logging = false;
        print_events = false;
        render_timer = false;
      };
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
        size = 11.0;
      };
      colors = {
        primary = {
          background = "0x2E3440";
          foreground = "0xD8DEE9";
        };
        normal = {
          black = "0x3B4252";
          blue = "0x81A1C1";
          cyan = "0x88C0D0";
          green = "0xA3BE8C";
          magenta = "0xB48EAD";
          red = "0xBF616A";
          white = "0xE5E9F0";
          yellow = "0xEBCB8B";
        };
        bright = {
          black = "0x4C566A";
          blue = "0x81A1C1";
          cyan = "0x8FBCBB";
          green = "0xA3BE8C";
          magenta = "0xB48EAD";
          red = "0xBF616A";
          white = "0xECEFF4";
          yellow = "0xEBCB8B";
        };
      };
      keyboard = {
        bindings = [
          {
            action = "Copy";
            key = "C";
            mods = "Shift|Control";
          }
          {
            action = "Paste";
            key = "V";
            mods = "Shift|Control";
          }
        ];
      };
      scrolling = {
        history = 2048;
        multiplier = 3;
      };
      window.opacity = 0.9;
      
    };
  };

}