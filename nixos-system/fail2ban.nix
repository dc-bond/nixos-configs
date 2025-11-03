{ 
  pkgs, 
  config, 
  lib, 
  configVars,
  ... 
}:

{

  services.fail2ban = {
    enable = true;
    
    # global settings
    maxretry = 5;
    bantime = "1h";
    findtime = "10m";
    
    # whitelist local networks to prevent lockouts
    ignoreIP = [
      "127.0.0.1/8"
      "192.168.0.0/16"
      "10.0.0.0/8"
      "172.16.0.0/12"
    ];
    
    # use default ban action with all ports blocked
    extraPackages = [ pkgs.ipset ];
    banaction = "iptables-ipset-proto6-allports";
    
    # incremental ban time for repeat offenders
    bantime-increment = {
      enable = true;
      formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # max one week
      overalljails = true;
    };

  };
  
}