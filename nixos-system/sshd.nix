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
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      LogLevel = "VERBOSE";
    };
  };

}