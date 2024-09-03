{ 
  pkgs, 
}:

pkgs.writeShellScriptBin "HDMI2" 
''
  ddcutil -d 1 setvcp 60 0x12 
''