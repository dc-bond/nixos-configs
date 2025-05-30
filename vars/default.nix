{ 
  inputs, 
  lib 
}:

{

  userName = "chris";
  userLastName = "Bond";
  userFullName = "Chris Bond";
  userEmail = "chris@dcbond.com";
  #userEmail = inputs.nix-secrets.userEmail;
  userGpgPubKey = "DB9ADBBE6FBD1F0E694AF25D012321D46E090E61";

  aspenLanIp = "192.168.1.2";
  aspenTailscaleIp = "100.68.250.108";
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

  frontCameraIp = "192.168.1.132";
  garageCameraIp = "192.168.1.131";
  gymCameraIp = "192.168.1.30";

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

  frigateSubnet = "172.21.13.0/25";
  frigateIp = "172.21.13.2";

  kasmwebSubnet = "172.21.14.0/25";

  kasmVpnSubnet = "172.21.15.0/25";
  kasmVpnIp = "172.21.15.99";

  librechatSubnet = "172.21.16.0/25";
  librechatApiIp = "172.21.16.2";
  librechatMongoIp = "172.21.16.3";
  librechatMeiliIp = "172.21.16.4";
  librechatVectorIp = "172.21.16.5";
  librechatRagIp = "172.21.16.6";
  
}