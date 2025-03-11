{ 
  pkgs,
  configVars,
  ... 
}: 

{

  services.SystemdJournal2Gelf = {
    enable = true;
    graylogServer = "${configVars.aspenLanIp}:12201";
  };

}