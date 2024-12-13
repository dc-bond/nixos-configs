{ 
  inputs, 
  lib 
}:

{

  userName = "chris";
  userEmail = "chris@dcbond.com";

  aspenLanIp = "192.168.1.189";
  aspenTailscaleIp = "100.111.119.3";
  thinkpadLanIp = "192.168.1.62";
  thinkpadTailscaleIp = "100.79.41.50";
  opticonLanIp = "192.168.1.2";
  opticonTailscaleIp = "100.92.225.78";
  cypressLanIp = "192.168.1.89";
  cypressTailscaleIp = "100.110.181.126";

  domain1 = "dcbond.com";
  domain2 = "opticon.dev";
  domain3 = "professorbond.com";
  domain3Short = "professorbond";

  lldapSubnet = "172.21.1.0/25";
  lldapIp = "172.21.1.2";
  postgres-lldapIp = "172.21.1.3";

  jellyseerrSubnet = "172.21.2.0/25";
  jellyseerrIp = "172.21.2.2";

  homeAssistantSubnet = "172.21.3.0/25";
  homeAssistantIp = "172.21.3.2";

  #kumaHostVethIp = "172.22.1.2";
  #kumaContainerVethIp = "172.22.1.3";










  
  #userFullName = inputs.nix-secrets.full-name;
  #userEmail = inputs.nix-secrets.userEmail;
  #persistFolder = "/persist";

}