{ 
  pkgs, 
  config 
}:

let
  secret = config.sops.secrets.homeTest.path;
in

pkgs.writeShellScriptBin "helloWorldHome" 
''
  echo "Hello World $(cat ${secret})";
''