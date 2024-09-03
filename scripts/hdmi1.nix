{ 
  pkgs, 
  config,
}:

pkgs.writeShellScriptBin "hdmi1" 
''
  ddcutil -d 1 setvcp 60 0x11 
''