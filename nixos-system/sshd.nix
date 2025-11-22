{ 
  pkgs, 
  lib,
  config,
  ... 
}: 

{

  services.openssh = lib.mkIf (config.hostSpecificConfigs.sshdPort != null) {
    enable = true;
    ports = [ config.hostSpecificConfigs.sshdPort ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      LogLevel = "VERBOSE"; # required for fail2ban to detect failed login attempts
    };
  };

}