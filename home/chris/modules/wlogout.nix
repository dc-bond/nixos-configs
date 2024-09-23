{
  config, 
  pkgs, 
  ...
}:

let 
  lockAction = "${pkgs.hyprlock}/bin/hyprlock";
in

{
  programs.wlogout = {
    enable = true;
    layout = [
      { 
        label = "lock"; 
        text = "Lock"; 
        action = lockAction; 
        keybind = "l"; 
      }
      {
        label = "hibernate"; 
        text = "Hibernate"; 
        action = "systemctl hibernate"; 
        keybind = "h"; 
      }
      { 
        label = "logout"; 
        text = "Logout"; 
        action = "hyprctl dispatch exit"; 
        keybind = "x"; 
      }
      { 
        label = "shutdown"; 
        text = "Shutdown"; 
        action = "systemctl poweroff"; 
        keybind = "s"; 
      }
      { 
        label = "suspend"; 
        text = "Suspend"; 
        action = "${lockAction} & systemctl suspend"; 
        keybind = "u"; 
      }
      { 
        label = "reboot"; 
        text = "Reboot"; 
        action = "systemctl reboot"; 
        keybind = "r"; 
      }
    ];
    style = ''

      * {
      	background-image: none;
      	box-shadow: none;
      }
      
      window {
      	background-color: rgba(12, 12, 12, 0.9);
      }
      
      button {
        border-radius: 0;
        border-color: black;
      	text-decoration-color: #FFFFFF;
        color: #FFFFFF;
      	background-color: #1E1E1E;
      	border-style: solid;
      	border-width: 1px;
      	background-repeat: no-repeat;
      	background-position: center;
      	background-size: 25%;
      }
      
      button:focus, button:active, button:hover {
      	background-color: #3700B3;
      	outline-style: none;
      }

      #lock {
        background-image: image(
          url("${pkgs.wlogout}/share/wlogout/icons/lock.png")
        );
      }

      #hibernate {
        background-image: image(
          url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png")
        );
      }
      
      #logout {
        background-image: image(
          url("${pkgs.wlogout}/share/wlogout/icons/logout.png")
        );
      }
      
      #suspend {
        background-image: image(
          url("${pkgs.wlogout}/share/wlogout/icons/suspend.png")
        );
      }
      
      #shutdown {
        background-image: image(
          url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png")
        );
      }
      
      #reboot {
        background-image: image(
          url("${pkgs.wlogout}/share/wlogout/icons/reboot.png")
        );
      }

    '';
  };
  
}