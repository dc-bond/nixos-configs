{ 
  pkgs, 
  config,
  configVars,
  lib,
  ... 
}: 

let
  hostname = config.networking.hostName;
  isServer = lib.elem hostname ["aspen" "juniper"]; # true if hostname is aspen or juniper
  isClient = lib.elem hostname ["thinkpad" "cypress"]; # true if hostname is thinkpad or cypress
in

{

  sops.secrets."${hostname}TailscaleAuthKey" = {};

  networking = {
    firewall.trustedInterfaces = ["tailscale0"];
    nat = lib.mkIf (hostname == "aspen") {
      enable = true;
      internalInterfaces = [ "tailscale0" ];
      externalInterface = "enp4s0";
    };
  };

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."${hostname}TailscaleAuthKey".path;
    useRoutingFeatures = if isServer then "server" else "client";
    extraDaemonFlags = ["--no-logs-no-support"];
    extraUpFlags = [
      "-ssh"
    ] 
    ++ lib.optionals isServer [ "--advertise-exit-node" ]
    ++ lib.optional (hostname == "aspen") "--advertise-routes=192.168.1.0/24,192.168.4.0/27"
    ++ lib.optionals isClient [ "--accept-routes" "--exit-node=${configVars.aspenTailscaleIp}" ];
    #++ lib.optional (hostname == "thinkpad") "--exit-node=${configVars.aspenTailscaleIp}"; # thinkpad laptop (client) always needs to default to using server exit node (aspen or juniper)
  };

}