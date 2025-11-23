{ 
  pkgs, 
  config,
  lib,
  ... 
}: 

{

  sops.secrets = {
    chrisPasswd.neededForUsers = true;
  };

  security.sudo = {
    wheelNeedsPassword = true;
    extraRules = [
      { 
        users = [ "chris" ];
        commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
      }
    ];
  };
  
  users.users = {
    
    root = {
      shell = pkgs.zsh;
    };

    chris = {
      isNormalUser = true;
      uid = 1000;
      hashedPasswordFile = config.sops.secrets.chrisPasswd.path;
      extraGroups = [ "wheel" ] 
        ++ lib.optional config.hardware.i2c.enable "i2c"
        ++ lib.optional config.virtualisation.docker.enable "docker";
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [ 
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDesi3Wba5w6/ZV0kgO4hCcG+n7cDwMuSGca/pCqW4zNlCA95Yd9enkQIAtJfUuXbMjZI7DPezcCptDMySUIBU+Lc3WKScJUsaAUjQCSAEv8E1mq6/qg2p2/0GSyl9NONE1iMlASiq8M/q04CL9E7SD6XJCKtqdAOP4mPi5+xzUJ85tvBlyeF8fTsDGQeUSkMm/N31zuymx9lIgf7KQ7bbV0L5Z5R7cSoGs2NrZDnhMpqFYVCh4LA/hhHg7ed8DE96xSJ6GUnulGVa1C8kCVa/fbU1tNBXfOBCooh7yL1MDGAyseAQC4g2ThwWR9Fpyy23Mn9hrr6tuoZ9lwji5RpthuHOYFey82kaDa50yop2BWwN3yXDZjnWJB6Eo8VrGql9o/WytjRh7YvMCC30jAEHEH8IVYGIT14zO9bC5CCCoP6wonkGjhlhdYJFKPQPKZ6X+bESXaC6+3FXY7CsiI/mWxjc5fdJVQRXZDrZaPwhvt292aSZCTY0sDcFwn8HeOO8= openpgp:0xE5DCB627"
      ];
    };

  };

}