{ pkgs, ... }: 

{

  programs.wlogout = {
    enable = true;
    style = 
    ''
      window {
        background: #16191C;
      }
      button {
        color: #AAB2BF;
      }
    '';
    layout =
    [
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
    ];
  };

}
