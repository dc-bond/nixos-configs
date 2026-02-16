{
  pkgs,
  lib,
  config,
  configVars,
  ...
}:

let

  hostData = configVars.hosts.${config.networking.hostName};
  aspenLanIp = configVars.hosts.aspen.networking.ipv4;
  aspenTailscaleIp = configVars.hosts.aspen.networking.tailscaleIp;
  juniperTailscaleIp = configVars.hosts.juniper.networking.tailscaleIp;

  # Replicate tailscale connection logic from tailscale.nix
  tsConfig = hostData.networking.tailscale or {};
  isExitNode = (tsConfig.role or "") == "exit-node";
  defaultExitNodeIp =
    if (tsConfig ? defaultExitNode) && (tsConfig.defaultExitNode != null)
    then configVars.hosts.${tsConfig.defaultExitNode}.networking.tailscaleIp
    else null;

  baseUpFlags = [ "--ssh" ]
    ++ lib.optionals isExitNode [ "--advertise-exit-node" ]
    ++ lib.optionals (tsConfig.advertiseRoutes == null) [ "--accept-routes" ]
    ++ lib.optional (tsConfig.advertiseRoutes != null)
        "--advertise-routes=${lib.concatStringsSep "," tsConfig.advertiseRoutes}";

  fullUpFlags = baseUpFlags
    ++ lib.optional (defaultExitNodeIp != null)
        "--exit-node=${defaultExitNodeIp}";

  networkTestScript = pkgs.writeShellScriptBin "network-test" ''
    #!/usr/bin/env bash

    echo ""
    echo "=========================================="
    echo "  Network & DNS Test"
    echo "=========================================="
    echo ""

    # Save initial Tailscale state
    INITIAL_TS_STATE="down"
    if ${pkgs.tailscale}/bin/tailscale status >/dev/null 2>&1; then
      INITIAL_TS_STATE="up"
      echo "Initial Tailscale state: UP"
    else
      echo "Initial Tailscale state: DOWN"
    fi
    echo ""

    # STEP 1: Force Tailscale OFF
    echo "=========================================="
    echo "STEP 1: Forcing Tailscale OFF"
    echo "=========================================="
    if [ "$INITIAL_TS_STATE" = "up" ]; then
      echo "Disconnecting Tailscale..."
      sudo ${pkgs.tailscale}/bin/tailscale down
      sleep 2
      echo "✓ Tailscale disconnected"
    else
      echo "✓ Tailscale already off"
    fi
    echo ""

    # STEP 2: Check internet connectivity
    echo "=========================================="
    echo "STEP 2: Internet Connectivity"
    echo "=========================================="
    if ! ${pkgs.iputils}/bin/ping -c 2 -W 3 1.1.1.1 >/dev/null 2>&1; then
      echo "✗ FATAL: Cannot reach 1.1.1.1 - no internet connectivity"
      exit 1
    fi
    echo "✓ Can reach 1.1.1.1 (Cloudflare)"

    if ! ${pkgs.iputils}/bin/ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1; then
      echo "⚠ Cannot reach 8.8.8.8 (Google)"
    else
      echo "✓ Can reach 8.8.8.8 (Google)"
    fi
    echo ""

    # STEP 3: Check DNS with Tailscale OFF
    echo "=========================================="
    echo "STEP 3: DNS Resolution (Tailscale OFF)"
    echo "=========================================="

    echo "Testing external domain..."
    if ${pkgs.dnsutils}/bin/dig google.com +short >/dev/null 2>&1; then
      echo "✓ google.com resolves"
    else
      echo "✗ FATAL: google.com does not resolve"
      exit 1
    fi

    echo "Testing internal domain..."
    if ${pkgs.dnsutils}/bin/dig home-assistant.opticon.dev +short >/dev/null 2>&1; then
      result=$(${pkgs.dnsutils}/bin/dig home-assistant.opticon.dev +short)
      echo "✓ home-assistant.opticon.dev resolves to: $result"
    else
      echo "⚠ home-assistant.opticon.dev does not resolve (aspen may be down)"
    fi

    echo ""
    echo "Which interface is handling DNS?"
    ${pkgs.systemd}/bin/resolvectl query google.com 2>/dev/null | grep -F -- "-- link:" | head -1 || echo "(could not determine)"
    echo ""

    # STEP 4: Turn Tailscale ON
    echo "=========================================="
    echo "STEP 4: Connecting Tailscale"
    echo "=========================================="
    echo "Connecting with flags: ${lib.concatStringsSep " " fullUpFlags}"
    if sudo ${pkgs.tailscale}/bin/tailscale up ${lib.concatStringsSep " " fullUpFlags} --reset >/dev/null 2>&1; then
      echo "✓ Tailscale connected"
      sleep 2
    else
      echo "✗ Failed to connect Tailscale (run 'tup' first if not authenticated)"
      exit 1
    fi
    echo ""

    # STEP 5: Check DNS with Tailscale ON
    echo "=========================================="
    echo "STEP 5: DNS Resolution (Tailscale ON)"
    echo "=========================================="

    echo "Testing external domain..."
    if ${pkgs.dnsutils}/bin/dig google.com +short >/dev/null 2>&1; then
      echo "✓ google.com resolves"
    else
      echo "✗ google.com does not resolve with Tailscale on"
    fi

    echo "Testing internal domain..."
    if ${pkgs.dnsutils}/bin/dig home-assistant.opticon.dev +short >/dev/null 2>&1; then
      result=$(${pkgs.dnsutils}/bin/dig home-assistant.opticon.dev +short)
      echo "✓ home-assistant.opticon.dev resolves to: $result"
    else
      echo "⚠ home-assistant.opticon.dev does not resolve"
    fi

    echo ""
    echo "Which interface is handling DNS?"
    ${pkgs.systemd}/bin/resolvectl query google.com 2>/dev/null | grep -F -- "-- link:" | head -1 || echo "(could not determine)"

    echo ""
    echo "Checking if MagicDNS is active..."
    if ${pkgs.systemd}/bin/resolvectl status 2>/dev/null | grep -q "100.100.100.100"; then
      echo "✓ MagicDNS detected (100.100.100.100)"
    else
      echo "⚠ MagicDNS not detected"
    fi
    echo ""

    # STEP 6: Turn Tailscale OFF again (test failback)
    echo "=========================================="
    echo "STEP 6: Testing DNS Failback"
    echo "=========================================="
    echo "Disconnecting Tailscale..."
    sudo ${pkgs.tailscale}/bin/tailscale down
    sleep 2
    echo "✓ Tailscale disconnected"
    echo ""

    echo "Testing first DNS query after disconnect (may timeout)..."
    start=$(date +%s)
    if ${pkgs.dnsutils}/bin/dig google.com +short >/dev/null 2>&1; then
      end=$(date +%s)
      duration=$((end - start))
      echo "✓ google.com resolves (took ''${duration}s)"
      if [ $duration -gt 4 ]; then
        echo "  (slow query - expected ~5s timeout during failover)"
      fi
    else
      echo "✗ google.com does not resolve after Tailscale disconnect"
    fi

    echo ""
    echo "Testing subsequent query (should be fast)..."
    start=$(date +%s)
    if ${pkgs.dnsutils}/bin/dig cloudflare.com +short >/dev/null 2>&1; then
      end=$(date +%s)
      duration=$((end - start))
      echo "✓ cloudflare.com resolves (took ''${duration}s)"
    else
      echo "✗ cloudflare.com does not resolve"
    fi

    echo ""
    echo "Which interface is handling DNS after failback?"
    ${pkgs.systemd}/bin/resolvectl query google.com 2>/dev/null | grep -F -- "-- link:" | head -1 || echo "(could not determine)"
    echo ""

    # STEP 7: Restore initial Tailscale state
    echo "=========================================="
    echo "STEP 7: Restoring Initial State"
    echo "=========================================="
    if [ "$INITIAL_TS_STATE" = "up" ]; then
      echo "Reconnecting Tailscale..."
      if sudo ${pkgs.tailscale}/bin/tailscale up ${lib.concatStringsSep " " fullUpFlags} --reset >/dev/null 2>&1; then
        echo "✓ Tailscale reconnected"
      else
        echo "⚠ Failed to reconnect - run 'tup' manually"
      fi
    else
      echo "✓ Tailscale left off (initial state)"
    fi
    echo ""

    echo "=========================================="
    echo "  Test Complete"
    echo "=========================================="
    echo ""
  '';

in

{
  environment.systemPackages = [ networkTestScript ];
}
