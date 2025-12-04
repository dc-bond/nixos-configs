{ 
  pkgs, 
  config,
  configVars,
  lib,
  ... 
}: 

let
  hostData = configVars.hosts.${config.networking.hostName};
  tsConfig = hostData.networking.tailscale or {};
  isExitNode = (tsConfig.role or "") == "exit-node";
  isClient = (tsConfig.role or "") == "client";
  defaultExitNodeIp = 
  if (tsConfig ? defaultExitNode) && (tsConfig.defaultExitNode != null)
  then configVars.hosts.${tsConfig.defaultExitNode}.networking.tailscaleIp
  else null;
  upFlags = [
    "--ssh"
  ] 
  ++ lib.optionals isExitNode [ "--advertise-exit-node" ]
  ++ lib.optionals isClient [ "--accept-routes" ]
  ++ lib.optional (tsConfig ? advertiseRoutes) 
      "--advertise-routes=${lib.concatStringsSep "," tsConfig.advertiseRoutes}"
  ++ lib.optional (defaultExitNodeIp != null)
      "--exit-node=${defaultExitNodeIp}";
  tailscaleUpScript = pkgs.writeShellScript "tailscale-up" ''
    ${pkgs.systemd}/bin/systemctl restart tailscaled.service
    sleep 2
    ${pkgs.tailscale}/bin/tailscale up ${lib.concatStringsSep " " upFlags}
  '';
in

{
  
  sops.secrets."${config.networking.hostName}TailscaleAuthKey" = {};

  networking = {
    firewall.trustedInterfaces = [ "tailscale0" ]; # allow all ports open on tailscale interface
    nat = lib.mkIf (tsConfig.enableNAT or false) { # allow clients to access advertised subnets without needing to use the subnet-advertising host as an exit-node
      enable = true;
      internalInterfaces = [ "tailscale0" ];
      externalInterface = hostData.networking.ethernetInterface;
    };
  };

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."${config.networking.hostName}TailscaleAuthKey".path;
    useRoutingFeatures = if isExitNode then "server" else "client";
    extraDaemonFlags = [ "--no-logs-no-support" ];
    extraUpFlags = upFlags;
  };

  programs.zsh.shellAliases = {
    tstat = "tailscale status";
    tdown = "sudo tailscale down";
    tup = "sudo ${tailscaleUpScript}";
  } // lib.optionalAttrs isClient (
    let
      exitNodes = lib.filterAttrs 
        (name: host: 
          (host.networking.tailscale.role or "") == "exit-node" 
          && host.networking.tailscaleIp != null
        ) 
        configVars.hosts;
      mkExitNodeAlias = name: host: {
        "t${name}" = "sudo tailscale down && sleep 2 && sudo tailscale up --ssh --accept-routes --exit-node=${host.networking.tailscaleIp}";
      };
    in
      lib.foldl' (acc: name: acc // mkExitNodeAlias name exitNodes.${name}) {} (lib.attrNames exitNodes)
  );

  # optimizations for subnet routers and exit nodes
  # https://tailscale.com/kb/1320/performance-best-practices#linux-optimizations-for-subnet-routers-and-exit-nodes
  systemd.services.tailscale-udp-optimization = lib.mkIf isExitNode {
    description = "Tailscale UDP GRO forwarding optimization";
    before = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [ ethtool iproute2 ];
    script = ''
      NETDEV=$(ip -o route get 1.1.1.1 | cut -f 5 -d " ")
      ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off
    '';
  };

}