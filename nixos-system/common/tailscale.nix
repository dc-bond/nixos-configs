{ 
  pkgs, 
  config,
  ... 
}: 

{

  sops.secrets = {
    tailscaleAuthKey = {};
  };

  services.tailscale = {
    enable = true;
    authKeyFile = "${config.sops.secrets.tailscaleAuthKey.path}";
    openFirewall = true;
  };
  
}