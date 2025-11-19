{ 
  pkgs, 
  config,
  ... 
}: 

{

  services = {
    samba = {
      enable = true;
      openFirewall = false; # tailscale access only
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "Media Upload Server";
          "security" = "user";
          "map to guest" = "never";
        };
        "media-uploads" = {
          "path" = "/srv/samba/media-uploads";
          "browseable" = "yes";
          "writable" = "yes";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "valid users" = "media-uploader";
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/samba/media-uploads 0755 media-uploader media-uploader -"
  ];

  users = {
    users.media-uploader = {
      isSystemUser = true;
      group = "media-uploader";
      description = "samba media-uploads directory user";
    };
    groups.media-uploader = {};
  };

}