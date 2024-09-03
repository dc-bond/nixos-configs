{ 
  pkgs, 
}:

pkgs.writeShellScriptBin "HDMI1" 
''
  ddcutil -d 1 setvcp 60 0x11 
''