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
        font-family: "Fira Sans Semibold", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
      	background-image: none;
      	transition: 20ms;
      	box-shadow: none;
      }
      
      window {
      	background: url("../ml4w/cache/blurred_wallpaper.png");
      	background-size: cover;
      }
      
      button {
      	color: #FFFFFF;
        font-size:20px;
        background-repeat: no-repeat;
      	background-position: center;
      	background-size: 25%;
      	border-style: solid;
      	background-color: rgba(12, 12, 12, 0.3);
      	border: 3px solid #FFFFFF;
        box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
      }
      
      button:focus,
      button:active,
      button:hover {
      color: @color11;
     	background-color: rgba(12, 12, 12, 0.5);
     	border: 3px solid @color11;
      }


      * {
        background-image: none;
      }
      window {
          font-family: Fira Code Regular Nerd Font Complete Mono, monospace;
          font-size: 12pt;
      color: #cad3f5; 
          background-color: rgba(30, 32, 48, 0);
      }
      /* window { */
      /*   background-color: rgba(12, 12, 12, 0.6); */
      /* } */
      button {
        margin: 10px;
        color: #ffffff;
        background-color: rgba(75, 0, 130, 0.75);
        border-style: solid;
        border-width: 1px;
        border-radius: 25px;
        background-repeat: no-repeat;
        background-position: center;
        background-size: 20%;
        box-shadow: none;
        text-shadow: none;
        animation: gradient_f 20s ease-in infinite;
      }
      button:focus {
          background-color: @wb-act-bg;
          background-size: 15%;
      }
      
      button:hover {
          background-color: @wb-hvr-bg;
          background-size: 30%;
          border-radius: 10px;
          animation: gradient_f 20s ease-in infinite;
          transition: all 0.3s cubic-bezier(.55,0.0,.28,1.682);
      }
      
      button:hover#lock {
          border-radius: 10px;
          margin : 5px 0px 5px 0px;
      }

      button:hover#hibernate {
          border-radius: 10px;
          margin : 5px 0px 5px 0px;
      }
      
      button:hover#logout {
          border-radius: 10px;
          margin : 5px 0px 5px 0px;
      }
      
      button:hover#suspend {
          border-radius: 10px;
          margin : 5px 0px 5px 0px;
      }
      
      button:hover#shutdown {
          border-radius: 10px;
          margin : 5px 0px 5px 0px;
      }
      
      button:hover#reboot {
          border-radius: 10px;
          margin : 5px 0px 5px 0px;
      }
      
      button:focus,
      button:active,
      button:hover {
        background-color: #2c114f;
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