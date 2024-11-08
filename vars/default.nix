{ 
  inputs, 
  lib 
}:

{

  userName = "chris";
  userEmail = "chris@dcbond.com";
  aspenIp = "192.168.1.189";
  thinkpadIp = "192.168.1.62";
  opticonIp = "192.168.1.2";
  vm1Ip = "192.168.1.199";
  domain1 = "dcbond.com";
  domain2 = "opticon.dev";
  domain3 = "professorbond.com";

  lldapSubnet = "172.21.1.0/25";
  lldapIp = "172.21.1.2";
  postgres-lldapIp = "172.21.1.3";
  jellyseerrSubnet = "172.22.1.0/25";
  jellyseerrIp = "172.22.1.2";

  uptime-kumaVethIp = "172.18.1.2";
  uptime-kumaContainerIp = "172.18.1.3";










  
  #userFullName = inputs.nix-secrets.full-name;
  #userEmail = inputs.nix-secrets.userEmail;
  #persistFolder = "/persist";

}