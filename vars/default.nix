{ 
  inputs, 
  lib 
}:

{

  userName = "chris";
  userEmail = "chris@dcbond.com";
  aspenIp = "192.168.1.186";
  thinkpadIp = "192.168.1.62";
  opticonIp = "192.168.1.2";
  vm1Ip = "192.168.1.199";
  domain1 = "dcbond.com";
  domain2 = "opticon.dev";
  domain3 = "professorbond.com";
  #userFullName = inputs.nix-secrets.full-name;
  #userEmail = inputs.nix-secrets.userEmail;
  #persistFolder = "/persist";
  #networking = import ./networking.nix { inherit lib; };

}