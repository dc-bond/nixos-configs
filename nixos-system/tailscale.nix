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
    ++ lib.optionals isClient [ "--accept-routes" ]
    ++ lib.optional (hostname == "aspen") "--advertise-routes=192.168.1.0/24,192.168.4.0/27"
    ++ lib.optional (hostname == "thinkpad") "--exit-node=${configVars.aspenTailscaleIp}"; # thinkpad laptop (client) always needs to default to using server exit node (aspen or juniper)
    #extraSetFlags = lib.optionals (hostname == "thinkpad") [ "--operator=${configVars.chrisUsername}" ]; # necessary for trayscale applet in plasma
  };

  # optimizations for subnet routers and exit nodes
  # https://tailscale.com/kb/1320/performance-best-practices#linux-optimizations-for-subnet-routers-and-exit-nodes
  systemd.services.tailscale-udp-optimization = lib.mkIf isServer {
    description = "Tailscale UDP GRO forwarding optimization";
    before = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [ 
      ethtool 
      iproute2 
    ];
    script = ''
      NETDEV=$(ip -o route get 1.1.1.1 | cut -f 5 -d " ")
      ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off
    '';
  };

}