{ 
  inputs, 
  lib 
}:

{

  userName = "chris";
  userFullName = "Chris Bond";
  userEmail = "chris@dcbond.com";

  aspenLanIp = "192.168.1.189";
  #aspenTailscaleIp = "";
  thinkpadLanIp = "192.168.1.62";
  thinkpadTailscaleIp = "100.90.150.101";
  opticonLanIp = "192.168.1.2";
  opticonTailscaleIp = "100.92.225.78";
  cypressLanIp = "192.168.1.89";
  cypressTailscaleIp = "100.84.248.69";

  domain1 = "dcbond.com";
  domain1Short = "dcbond";
  domain2 = "opticon.dev";
  domain2Short = "opticon";
  domain3 = "professorbond.com";
  domain3Short = "professorbond";

  piholeSubnet = "172.21.1.0/25";
  piholeIp = "172.21.1.2";
  unboundIp = "172.21.1.3";

  jellyseerrSubnet = "172.21.2.0/25";
  jellyseerrIp = "172.21.2.2";

  #homeAssistantSubnet = "172.21.3.0/25";
  #homeAssistantIp = "172.21.3.2";

  zwaveJsSubnet = "172.21.4.0/25";
  zwaveJsIp = "172.21.4.2";

  actualSubnet = "172.21.5.0/25";
  actualIp = "172.21.5.2";

  #kumaHostVethIp = "172.22.1.2";
  #kumaContainerVethIp = "172.22.1.3";




  
  #userEmail = inputs.nix-secrets.userEmail;



  # rm rf /var/lib/tailscale on cypress
  # nix garbage collect on cypress
  # rebuild cypress
  # authroize exit node
  # copy ip address here
  # rebuild thinkpad
  # copy ip address here
  # verify

}