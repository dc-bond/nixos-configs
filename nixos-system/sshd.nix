{ 
  pkgs, 
  lib,
  config,
  configVars,
  ... 
}: 

let
  hostData = configVars.hosts.${config.networking.hostName};
in

{

  services.openssh = lib.mkIf (hostData.networking.sshPort != null) {
    enable = true;
    ports = [ hostData.networking.sshPort ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      LogLevel = "VERBOSE";
    };
  };

}