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
  # base flags without exit node (for use in exit node switching)
  baseUpFlags = [ "--ssh" ]
  ++ lib.optionals isExitNode [ "--advertise-exit-node" ]
  ++ lib.optionals (tsConfig.advertiseRoutes == null) [ "--accept-routes" ]
  ++ lib.optional (tsConfig.advertiseRoutes != null)
      "--advertise-routes=${lib.concatStringsSep "," tsConfig.advertiseRoutes}";

  # full flags including configured default exit node
  fullUpFlags = baseUpFlags
    ++ lib.optional (defaultExitNodeIp != null)
        "--exit-node=${defaultExitNodeIp}";

  # first-time auth script - uses auth key only when needed, includes default exit node from config
  tailscaleUp = pkgs.writeShellScript "tailscaleUp" ''
    echo "Connecting to Tailscale with all default flags..."
    if [ -f /var/lib/tailscale/tailscaled.state ]; then
      # already authenticated - reconnect with existing identity
      ${pkgs.tailscale}/bin/tailscale up ${lib.concatStringsSep " " fullUpFlags} --reset
    else
      # first-time connection - use auth key (no --reset needed on first connection)
      ${pkgs.tailscale}/bin/tailscale up \
        --auth-key="$(cat ${config.sops.secrets."${config.networking.hostName}TailscaleAuthKey".path})" \
        ${lib.concatStringsSep " " fullUpFlags}
    fi
  '';

  # manual reconnect script - for use after 'tailscale down', connects without exit node
  tailscaleNoExit = pkgs.writeShellScript "tailscaleNoExit" ''
    echo "Connecting to Tailscale (no exit node)..."
    ${pkgs.tailscale}/bin/tailscale up ${lib.concatStringsSep " " baseUpFlags} --reset
  '';

  # exit node switcher script - manually switch to a specific exit node
  tailscaleSwitchExit = pkgs.writeShellScript "tailscaleSwitchExit" ''
    EXIT_NODE="$1"
    if [[ -z "$EXIT_NODE" ]]; then
      echo "Usage: tailscale-switch-exit <exit-node-ip>"
      exit 1
    fi
    echo "Switching to exit node: $EXIT_NODE"
    ${pkgs.tailscale}/bin/tailscale up \
      ${lib.concatStringsSep " " baseUpFlags} \
      --exit-node="$EXIT_NODE" \
      --reset
  '';

in

{
  
  sops.secrets."${config.networking.hostName}TailscaleAuthKey" = {}; # authKeys created in tailscale console are one-time use only; manually run 'tup' on fresh install to connect; authKey in sops then becomes deprecated

  networking = {
    firewall.trustedInterfaces = [ "tailscale0" ]; # allow all ports open on tailscale interface
    nat = lib.mkIf (tsConfig.advertiseRoutes != null) { # allow clients to access advertised subnets without needing to use the subnet-advertising host as an exit-node
      enable = true;
      internalInterfaces = [ "tailscale0" ];
      externalInterface = hostData.networking.ethernetInterface;
    };
  };

  services.tailscale = {
    enable = true;
    #authKeyFile = config.sops.secrets."${config.networking.hostName}TailscaleAuthKey".path; # remove to prevent nix's default tailscale autoconnect service from being created
    useRoutingFeatures = if isExitNode then "server" else "client"; # configures kernel routing (e.g. "net.ipv4.ip_forward" = 1)
    extraDaemonFlags = [ "--no-logs-no-support" ];
    #extraUpFlags = fullUpFlags; # only used with nix's default tailscale autoconnect service
  };

  programs.zsh.shellAliases = {
    tstat = "tailscale status";
    tdown = "sudo tailscale down";
    tup = "sudo ${tailscaleUp}";  # reconnect with full default flags (includes default exit node if configured)
    tupnoexit = "sudo ${tailscaleNoExit}";  # connect without exit node
  } // lib.optionalAttrs isClient (
    let
      exitNodes = lib.filterAttrs
        (name: host:
          (host.networking.tailscale.role or "") == "exit-node"
          && host.networking.tailscaleIp != null
        )
        configVars.hosts;
      mkExitNodeAlias = name: host: {
        "tup${name}" = "sudo ${tailscaleSwitchExit} ${host.networking.tailscaleIp}";
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
    path = with pkgs; [ ethtool ];
    script = ''
      # use configured interface directly instead of route detection (avoids DHCP race condition)
      ethtool -K ${hostData.networking.ethernetInterface} rx-udp-gro-forwarding on rx-gro-list off
    '';
  };

}