{ 
  inputs, 
  lib 
}:

{

  userName = "chris";
  userFullName = "Chris Bond";
  userEmail = "chris@dcbond.com";
  userGpgPubKey = "DB9ADBBE6FBD1F0E694AF25D012321D46E090E61";

  aspenLanIp = "192.168.1.189";
  #aspenTailscaleIp = "";
  thinkpadLanIp = "192.168.1.62";
  thinkpadTailscaleIp = "100.90.150.101";
  opticonLanIp = "192.168.1.2";
  opticonTailscaleIp = "100.92.225.78";
  cypressLanIp = "192.168.1.89";
  cypressTailscaleIp = "100.84.248.69";

  unifiUsgIp = "192.168.1.1";
  unifiSwitch8Ip = "192.168.1.199";
  unifiSwitch8LiteIp = "192.168.1.151";
  unifiUapGarageIp = "192.168.1.191";
  unifiUapLivingRoomIp = "192.168.1.173";

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

  unifiSubnet = "172.21.3.0/25";
  unifiControllerIp = "172.21.3.2";
  unifiMongoIp = "172.21.3.3";

  zwaveJsSubnet = "172.21.4.0/25";
  zwaveJsIp = "172.21.4.2";

  actualSubnet = "172.21.5.0/25";
  actualIp = "172.21.5.2";

  favaSubnet = "172.21.6.0/25";
  favaIp = "172.21.6.2";

  recipesageSubnet = "172.21.7.0/25";
  recipesageProxyIp = "172.21.7.2";
  recipesageStaticIp = "172.21.7.3";
  recipesageApiIp = "172.21.7.4";
  recipesageTypesenseIp = "172.21.7.5";
  recipesagePushpinIp = "172.21.7.6";
  recipesagePostgresIp = "172.21.7.7";
  recipesageBrowserlessIp = "172.21.7.8";
  recipesageIngredientIp = "172.21.7.9";

  wordpressDcbondSubnet = "172.21.8.0/25";
  wordpressDcbondIp = "172.21.8.2";
  wordpressDcbondMysqlIp = "172.21.8.3";

  chromiumSubnet = "172.21.9.0/25";
  chromiumVpnIp = "172.21.9.2";

  searxngSubnet = "172.21.10.0/25";
  searxngIp = "172.21.10.2";

  traefikCertsSubnet = "172.21.11.0/25";
  traefikCertsIp = "172.21.11.2";

  arrStackSubnet = "172.21.12.0/25";
  arrVpnIp = "172.21.12.2";




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