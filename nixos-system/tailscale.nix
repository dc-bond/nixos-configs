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
    firewall.trustedInterfaces = [ "tailscale0" ]; # allow all ports open on tailscale interface
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
    ++ lib.optional (hostname == "thinkpad") "--exit-node=${configVars.hosts.aspen.networking.tailscaleIp}"; # thinkpad laptop (client) always needs to default to using server exit node (aspen or juniper)
  };

  programs.zsh = {
    shellAliases = {
      tstat = "sudo tailscale status";
      tdown = "sudo tailscale down";
    } // lib.optionalAttrs isClient {
      taspen = "sudo tailscale down && sleep 5 && sudo tailscale up --ssh --accept-routes --exit-node=${configVars.hosts.aspen.networking.tailscaleIp} --reset";
      tjuniper = "sudo tailscale down && sleep 5 && sudo tailscale up --ssh --accept-routes --exit-node=${configVars.hosts.juniper.networking.tailscaleIp} --reset";
      tup = "sudo tailscale down && sleep 5 && sudo tailscale up --ssh --accept-routes --reset";
    };
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



#{
#  # Service to automatically retrieve Taildrop files
#  systemd.services.taildrop-receive = {
#    description = "Automatically receive Taildrop files";
#    after = [ "tailscale.service" ];
#    wants = [ "tailscale.service" ];
#    wantedBy = [ "multi-user.target" ];
#    
#    serviceConfig = {
#      Type = "simple";
#      User = "chris";
#      Group = "users";
#      Restart = "always";
#      RestartSec = "10s";
#    };
#    
#    path = [ config.services.tailscale.package ];
#    
#    script = ''
#      # Destination directory
#      DEST="${config.hostSpecificConfigs.storageDrive1}/samba/media-uploads"
#      
#      # Poll for new files every 5 seconds
#      while true; do
#        # Get list of waiting files
#        FILES=$(tailscale file get --wait --conflict=rename "$DEST" 2>&1 || true)
#        
#        if [[ $FILES != *"no files waiting"* ]] && [[ -n "$FILES" ]]; then
#          echo "Received files via Taildrop: $FILES"
#          # Your processing script could run here
#        fi
#        
#        sleep 5
#      done
#    '';
#  };
#
#  # Ensure destination directory exists
#  systemd.tmpfiles.rules = [
#    "d ${config.hostSpecificConfigs.storageDrive1}/samba/media-uploads 0755 chris users -"
#  ];
#}