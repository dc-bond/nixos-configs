{ 
  inputs, 
  lib 
}:

{

  userName = "chris";
  userEmail = "chris@dcbond.com";
  aspenLanIp = "192.168.1.172";

  aspenTailscaleIp = "100.73.117.29";
  thinkpadLanIp = "192.168.1.62";
  thinkpadTailscaleIp = "100.79.41.50";
  opticonLanIp = "192.168.1.2";
  opticonTailscaleIp = "100.92.225.78";
  vm1LanIp = "192.168.1.199";
  
  domain1 = "dcbond.com";
  domain2 = "opticon.dev";
  domain3 = "professorbond.com";

  lldapSubnet = "172.21.1.0/25";
  lldapIp = "172.21.1.2";
  postgres-lldapIp = "172.21.1.3";
  jellyseerrSubnet = "172.22.1.0/25";
  jellyseerrIp = "172.22.1.2";

  kumaHostVethIp = "fc01::2";
  kumaContainerVethIp = "fc01::3";










  
  #userFullName = inputs.nix-secrets.full-name;
  #userEmail = inputs.nix-secrets.userEmail;
  #persistFolder = "/persist";

}