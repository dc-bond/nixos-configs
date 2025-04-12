{ 
  pkgs,
  lib,
  ... 
}: 

{

  services.SystemdJournal2Gelf = {
    enable = true;
    graylogServer = "127.0.0.1:12201";
  };

}