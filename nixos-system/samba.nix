{
  pkgs,
  config,
  ...
}:

{

  sops.secrets.sambaPasswd = {};

  #networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 445 ]; # open samba port on tailscale interface to recieve uploads pushed from outside clients

  services = {
    samba = {
      enable = true;
      nmbd.enable = false;
      winbindd.enable = false;
      openFirewall = false; # tailscale access only
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "Media Upload Server";
          "security" = "user";
          "map to guest" = "never";
        };
        "media-uploads" = {
          "path" = "${config.dataPool.path}/samba/media-uploads";
          "browseable" = "yes";
          "writable" = "yes";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "valid users" = "samba-uploader";
          "force user" = "chris";
          "force group" = "users";
        };
        "general-uploads" = {
          "path" = "${config.dataPool.path}/samba/general-uploads";
          "browseable" = "yes";
          "writable" = "yes";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "valid users" = "samba-uploader";
          "force user" = "chris";
          "force group" = "users";
        };
      };
    };
  };

  systemd = {

    tmpfiles.rules = [
      "d ${config.dataPool.path}/samba 0755 chris users -"
      "d ${config.dataPool.path}/samba/media-uploads 0755 chris users -"
      "d ${config.dataPool.path}/samba/general-uploads 0755 chris users -"
    ];

    services.samba-setup-password = {
      description = "set samba user password";
      after = [ "samba-smbd.service" "systemd-tmpfiles-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        password=$(cat ${config.sops.secrets.sambaPasswd.path})
        (echo "$password"; echo "$password") | ${pkgs.samba}/bin/smbpasswd -a -s samba-uploader
      '';
    };

  };

  users = {
    users.samba-uploader = {
      isSystemUser = true;
      group = "samba-uploader";
      description = "samba upload directory user";
    };
    groups.samba-uploader = {};
  };

}