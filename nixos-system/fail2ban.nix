{ 
  pkgs, 
  config, 
  lib, 
  configVars,
  ... 
}:

{

  services.fail2ban = {
    # global settings
    enable = true;
    maxretry = 5;
    bantime = "1h";
    extraPackages = [ pkgs.ipset ];
    banaction = "iptables-ipset-proto6-allports"; # use ipset to ban ipv4 and ipv6 on all ports for offending ip
    bantime-increment = { # incremental ban time for repeat offendending ips
      enable = true;
      formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # max one week
      overalljails = true; # calculate bandtime based on all jail violations
    };
    ignoreIP = [ # whitelist local networks to prevent lockouts
      "127.0.0.1/8"
      "192.168.0.0/16"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "100.64.0.0/10" # tailscale CGNAT range
    ];
    # configs and overrides for specific services (aka "jails")
    jails = {
      sshd.settings = {
        enabled = true;
        maxretry = 3; # stricter than global 5
        findtime = "5m";
      };
    };
  };
  
}