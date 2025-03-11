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

  #services.filebeat = {
  #  enable = true;
  #  inputs = {
  #    journald = {
  #      type = "journald";
  #      id = "everything";
  #    };
  #  };
  #  settings = {
  #    output = {
  #      elasticsearch = { # despite being called elasticsearch, graylog is acting as ingester
  #        hosts = [ "127.0.0.1:5044" ];  # graylog ingest
  #      };
  #    };
  #  };
  #};

}