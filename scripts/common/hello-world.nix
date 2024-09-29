{ 
  pkgs, 
  config 
}:

let
  secret = config.sops.secrets.test.path;
in

pkgs.writeShellScriptBin "hello-world" 
''
  echo "Hello World $(cat ${secret})";
''