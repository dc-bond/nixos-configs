{
  pkgs,
  lib,
  config,
  configVars,
  ...
}:

let
  sshPort = configVars.hosts.${config.networking.hostName}.networking.sshPort;
in

{

  services.openssh = lib.mkIf (sshPort != null) {
    enable = true;
    ports = [ sshPort ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      LogLevel = "VERBOSE";
    };
  };

}