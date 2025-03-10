{ 
  pkgs, 
  ... 
}: 

{

  services.filebeat = {
    enable = true;
    inputs = {
      journald.id = "everything";
    };
    settings = {
      output.logstash = {
        hosts = [ "127.0.0.1:5044" ];  # graylog logstash input
      };
    };
  };

}