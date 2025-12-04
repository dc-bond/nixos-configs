{ 
  pkgs, 
  config,
  configVars,
  lib,
  ... 
}: 

let

  hostData = configVars.hosts.${config.networking.hostName};

  mkUser = username: 
    let
      userInfo = configVars.users.${username};
      shellPkg = if userInfo.shell == "zsh" then pkgs.zsh else pkgs.bash;
    in 
    {
      isNormalUser = true;
      uid = userInfo.uid;
      hashedPasswordFile = config.sops.secrets."${username}Passwd".path;
      extraGroups = [ "wheel" ] 
        ++ lib.optional config.hardware.i2c.enable "i2c"
        ++ lib.optional config.virtualisation.docker.enable "docker";
      shell = shellPkg;
      openssh.authorizedKeys.keys = userInfo.sshKeys;
    };

  # users on this host who get passwordless sudo
  sudoNoPasswdUsers = lib.filter 
    (u: configVars.users.${u}.sudoNoPasswd or false) 
    hostData.users;

in

{
  # auto-generate sops secrets for each user on this host
  sops.secrets = lib.genAttrs 
    (map (u: "${u}Passwd") hostData.users)
    (_: { neededForUsers = true; });

  security.sudo = {
    wheelNeedsPassword = true;
    extraRules = lib.optional (sudoNoPasswdUsers != []) {
      users = sudoNoPasswdUsers;
      commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
    };
  };
  
  users.users = {
    root = {
      shell = pkgs.zsh;
    };
  } // lib.genAttrs hostData.users mkUser;
  
}