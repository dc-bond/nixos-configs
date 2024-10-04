{ 
  pkgs, 
  config, 
  ... 
}: 

{

  sops.secrets.chrisPasswd.neededForUsers = true;

  users.users = {
    chris = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.chrisPasswd.path; # create hashed password with 'echo "password" | mkpasswd -s'
      extraGroups = [
        "wheel" 
        "i2c" # for controlling i2c/ddcutil
      ];
      shell = pkgs.zsh; # user-specific z-shell configs in home.nix
      openssh.authorizedKeys.keys = [ 
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDJZBJOhg+DeRoH1UljG6FniW66qtYVmJNYtreg54WL3 chris@dcbond.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+A1i8WE8o6dA4mtJo+6qe8BcLl7mYq/zkd0TOx7lGI xixor@termius"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOjjAo9m/rrJ2DsHAWQO4lNnLmbtMyQhV1LevHzXVf7j chris@vm1"
      ];
    };
    root = {
      shell = pkgs.zsh;
    };
  };

}