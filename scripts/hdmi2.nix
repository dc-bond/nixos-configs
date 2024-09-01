{ 
  pkgs, 
  config 
}:

pkgs.writeShellScriptBin "hdmi2" 
''
  #ddcutil -d 1 setvcp 60 0x12
  #ddcutil -d 1 setvcp D6 05
''