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
  isClient = (hostData.networking.tailscale.role or "") == "client";

  networkTestScript = pkgs.writeShellScriptBin "network-test" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Color codes
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    RESET='\033[0m'

    # Test domains
    EXTERNAL_DOMAIN="cloudflare.com"
    EXTERNAL_DOMAIN2="google.com"
    AD_DOMAIN="doubleclick.net"
    INTERNAL_DOMAIN_ASPEN="home-assistant.opticon.dev"
    INTERNAL_DOMAIN_JUNIPER="grafana.opticon.dev"
    INTERNAL_DOMAIN_NEXTCLOUD="nextcloud.opticon.dev"

    # Expected IPs
    ASPEN_LAN_IP="${aspenLanIp}"
    ASPEN_TS_IP="${aspenTailscaleIp}"
    JUNIPER_TS_IP="${juniperTailscaleIp}"

    # Test counters
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_WARNING=0

    # Helper functions
    print_header() {
      echo -e "\n''${BOLD}''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${RESET}"
      echo -e "''${BOLD}''${BLUE}  $1''${RESET}"
      echo -e "''${BOLD}''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${RESET}\n"
    }

    print_subheader() {
      echo -e "''${CYAN}''${BOLD}▶ $1''${RESET}"
    }

    print_pass() {
      echo -e "  ''${GREEN}✓''${RESET} $1"
      ((TESTS_PASSED++))
    }

    print_fail() {
      echo -e "  ''${RED}✗''${RESET} $1"
      ((TESTS_FAILED++))
    }

    print_warn() {
      echo -e "  ''${YELLOW}⚠''${RESET} $1"
      ((TESTS_WARNING++))
    }

    print_info() {
      echo -e "  ''${BLUE}ℹ''${RESET} $1"
    }

    print_explain() {
      echo -e "    ''${YELLOW}→''${RESET} ''${YELLOW}$1''${RESET}"
    }

    # Test DNS resolution with timing
    test_dns() {
      local domain=$1
      local server=$2
      local server_name=$3
      local expected_result=$4  # "success", "blocked", or "fail-ok"

      local start_time=$(date +%s.%N)
      local result
      result=$(${pkgs.dnsutils}/bin/dig "$domain" @"$server" +short +time=5 +tries=1 2>&1 || echo "TIMEOUT")
      local end_time=$(date +%s.%N)
      local duration=$(echo "$end_time - $start_time" | ${pkgs.bc}/bin/bc)

      if [[ "$result" == "TIMEOUT" ]] || [[ "$result" == *"connection timed out"* ]]; then
        if [[ "$expected_result" == "fail-ok" ]]; then
          print_warn "$domain → $server_name (timeout after ''${duration}s) - Expected in this scenario"
        else
          print_fail "$domain → $server_name (timeout after ''${duration}s)"
          print_explain "DNS server $server is not responding"
        fi
      elif [[ "$result" == "0.0.0.0" ]]; then
        if [[ "$expected_result" == "blocked" ]]; then
          print_pass "$domain → $server_name (blocked: 0.0.0.0, ''${duration}s)"
        else
          print_fail "$domain → $server_name (unexpectedly blocked: 0.0.0.0)"
        fi
      elif [[ -z "$result" ]]; then
        print_fail "$domain → $server_name (no result)"
      else
        if [[ "$expected_result" == "success" ]]; then
          print_pass "$domain → $server_name ($result, ''${duration}s)"
        elif [[ "$expected_result" == "blocked" ]]; then
          print_warn "$domain → $server_name ($result, ''${duration}s) - Should be blocked"
        else
          print_pass "$domain → $server_name ($result, ''${duration}s)"
        fi
      fi

      echo "$result"
    }

    # Check if Tailscale is connected
    is_tailscale_connected() {
      ${pkgs.tailscale}/bin/tailscale status >/dev/null 2>&1 && \
      [[ $(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.BackendState') == "Running" ]]
    }

    # Get current DNS server from systemd-resolved
    get_current_dns() {
      if command -v ${pkgs.systemd}/bin/resolvectl >/dev/null 2>&1; then
        ${pkgs.systemd}/bin/resolvectl status 2>/dev/null | grep "Current DNS Server:" | awk '{print $4}' || echo "unknown"
      else
        echo "not-using-resolved"
      fi
    }

    # Monitor DNS configuration transition in real-time
    monitor_dns_transition() {
      local action=$1  # "disconnect" or "connect"
      local max_wait=10
      local interval=0.5
      local elapsed=0

      print_info "Monitoring DNS configuration change..."
      local initial_dns=$(get_current_dns)
      print_info "  Initial DNS: $initial_dns"

      while (( $(echo "$elapsed < $max_wait" | ${pkgs.bc}/bin/bc -l) )); do
        sleep $interval
        elapsed=$(echo "$elapsed + $interval" | ${pkgs.bc}/bin/bc)

        local current_dns=$(get_current_dns)

        if [[ "$current_dns" != "$initial_dns" ]]; then
          print_pass "DNS changed after ''${elapsed}s: $initial_dns → $current_dns"
          return 0
        fi
      done

      local final_dns=$(get_current_dns)
      if [[ "$final_dns" == "$initial_dns" ]]; then
        print_warn "DNS did not change after ''${max_wait}s (still: $final_dns)"
      else
        print_pass "DNS changed: $initial_dns → $final_dns"
      fi
    }

    # Save initial Tailscale state
    INITIAL_TS_STATE="disconnected"
    if is_tailscale_connected; then
      INITIAL_TS_STATE="connected"
      print_info "Initial Tailscale state: connected"
    else
      print_info "Initial Tailscale state: disconnected"
    fi

    # Force Tailscale OFF to start tests from known state
    print_header "SETUP: Forcing Tailscale OFF for baseline tests"
    if is_tailscale_connected; then
      print_info "Disconnecting Tailscale to establish baseline..."
      sudo ${pkgs.tailscale}/bin/tailscale down
      monitor_dns_transition "disconnect"
      sleep 1
    else
      print_pass "Tailscale already disconnected"
    fi

    print_header "PHASE 1: Basic Connectivity (Tailscale: OFF)"

    print_subheader "Network Interfaces"
    ${pkgs.iproute2}/bin/ip -brief addr show | grep -v "^lo" | while read line; do
      if echo "$line" | grep -q "UP"; then
        print_pass "$line"
      else
        print_warn "$line"
      fi
    done

    print_subheader "Internet Connectivity"
    if ${pkgs.iputils}/bin/ping -c 2 -W 3 1.1.1.1 >/dev/null 2>&1; then
      print_pass "Can reach 1.1.1.1 (Cloudflare DNS)"
    else
      print_fail "Cannot reach 1.1.1.1 - No internet connectivity"
      print_explain "Check physical network connection and routing"
    fi

    if ${pkgs.iputils}/bin/ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1; then
      print_pass "Can reach 8.8.8.8 (Google DNS)"
    else
      print_fail "Cannot reach 8.8.8.8"
    fi

    print_subheader "Default Route"
    default_route=$(${pkgs.iproute2}/bin/ip route show default | head -1)
    if [[ -n "$default_route" ]]; then
      print_pass "Default route: $default_route"
    else
      print_fail "No default route configured"
    fi

    # PHASE 2: DNS Configuration & LAN Resolution
    print_header "PHASE 2: DNS Configuration & LAN Resolution (Tailscale: OFF)"

    print_subheader "Current DNS Configuration"
    if command -v ${pkgs.systemd}/bin/resolvectl >/dev/null 2>&1; then
      dns_status=$(${pkgs.systemd}/bin/resolvectl status 2>/dev/null || echo "not available")

      # Extract DNS servers
      current_dns=$(echo "$dns_status" | grep "Current DNS Server:" | awk '{print $4}')
      all_dns=$(echo "$dns_status" | grep -A 5 "DNS Servers:" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}|([0-9a-fA-F]{0,4}:){7}[0-9a-fA-F]{0,4}' | head -5)

      if [[ -n "$current_dns" ]]; then
        print_info "Current DNS Server: $current_dns"
      fi

      if [[ -n "$all_dns" ]]; then
        echo -e "  ''${BLUE}ℹ''${RESET} Configured DNS Servers:"
        echo "$all_dns" | while read dns; do
          echo "    - $dns"
        done
      fi
    else
      print_info "/etc/resolv.conf:"
      cat /etc/resolv.conf | grep nameserver | while read line; do
        echo "    $line"
      done
    fi

    print_subheader "External DNS Resolution (via system default)"
    test_dns "$EXTERNAL_DOMAIN" "127.0.0.1" "System Default" "success" >/dev/null
    test_dns "$EXTERNAL_DOMAIN2" "127.0.0.1" "System Default" "success" >/dev/null

    print_subheader "Ad Blocking Test (Pi-hole)"
    ad_result=$(test_dns "$AD_DOMAIN" "127.0.0.1" "System Default" "blocked")

    print_subheader "Internal Domain Resolution"
    test_dns "$INTERNAL_DOMAIN_ASPEN" "127.0.0.1" "System Default" "success" >/dev/null
    test_dns "$INTERNAL_DOMAIN_JUNIPER" "127.0.0.1" "System Default" "success" >/dev/null
    test_dns "$INTERNAL_DOMAIN_NEXTCLOUD" "127.0.0.1" "System Default" "success" >/dev/null

    # PHASE 3: Direct DNS Server Queries (Tailscale: OFF)
    print_header "PHASE 3: Direct DNS Server Queries (Tailscale: OFF)"

    print_subheader "Query aspen via LAN IP ($ASPEN_LAN_IP)"
    if ${pkgs.iputils}/bin/ping -c 1 -W 2 "$ASPEN_LAN_IP" >/dev/null 2>&1; then
      print_pass "Can reach aspen on LAN"
      test_dns "$INTERNAL_DOMAIN_ASPEN" "$ASPEN_LAN_IP" "aspen LAN" "success" >/dev/null
      test_dns "$EXTERNAL_DOMAIN" "$ASPEN_LAN_IP" "aspen LAN" "success" >/dev/null
    else
      print_fail "Cannot reach aspen on LAN ($ASPEN_LAN_IP)"
      print_explain "aspen may be down or network connectivity issue"
    fi

    print_subheader "Query public DNS servers"
    test_dns "$EXTERNAL_DOMAIN" "1.1.1.1" "Cloudflare" "success" >/dev/null
    test_dns "$EXTERNAL_DOMAIN" "9.9.9.9" "Quad9" "success" >/dev/null

    # PHASE 4: Connect Tailscale & Test DNS Integration
    print_header "PHASE 4: Connecting Tailscale & Testing DNS Integration"

    print_info "Connecting Tailscale..."
    if sudo ${pkgs.tailscale}/bin/tailscale up --accept-routes 2>/dev/null; then
      print_pass "Tailscale connected successfully"
      monitor_dns_transition "connect"
      sleep 1
    else
      print_fail "Failed to connect Tailscale"
      print_explain "Run 'tup' manually to authenticate"
    fi

    if is_tailscale_connected; then
      print_subheader "Tailscale Status"
      ts_status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null)
      ts_exit_node=$(echo "$ts_status" | ${pkgs.jq}/bin/jq -r '.ExitNodeStatus.TailscaleIPs[0] // "none"')

      if [[ "$ts_exit_node" != "none" ]]; then
        print_info "Exit Node: $ts_exit_node"
      else
        print_info "No exit node configured"
      fi

      print_subheader "DNS Resolution via Tailscale MagicDNS"

      # Check if MagicDNS is active
      if ${pkgs.systemd}/bin/resolvectl status 2>/dev/null | grep -q "100.100.100.100"; then
        print_pass "MagicDNS active (100.100.100.100)"

        print_info "Testing resolution speed with Tailscale DNS..."
        test_dns "$EXTERNAL_DOMAIN" "127.0.0.1" "via Tailscale" "success" >/dev/null
        test_dns "$INTERNAL_DOMAIN_ASPEN" "127.0.0.1" "via Tailscale" "success" >/dev/null
        test_dns "$INTERNAL_DOMAIN_JUNIPER" "127.0.0.1" "via Tailscale" "success" >/dev/null

        # Verify which Pi-hole is answering
        print_info "Verifying which Pi-hole answers via MagicDNS..."
        test_dns "$INTERNAL_DOMAIN_JUNIPER" "100.100.100.100" "MagicDNS→juniper" "success" >/dev/null
      else
        print_warn "MagicDNS not detected in DNS configuration"
        print_explain "Check Tailscale DNS settings: tailscale status"
      fi

      print_subheader "Direct Queries via Tailscale IPs"
      if ${pkgs.iputils}/bin/ping -c 1 -W 2 "$ASPEN_TS_IP" >/dev/null 2>&1; then
        print_pass "Can reach aspen via Tailscale"
        test_dns "$INTERNAL_DOMAIN_ASPEN" "$ASPEN_TS_IP" "aspen Tailscale" "success" >/dev/null
      else
        print_fail "Cannot reach aspen via Tailscale ($ASPEN_TS_IP)"
      fi

      if ${pkgs.iputils}/bin/ping -c 1 -W 2 "$JUNIPER_TS_IP" >/dev/null 2>&1; then
        print_pass "Can reach juniper via Tailscale"
        test_dns "$INTERNAL_DOMAIN_JUNIPER" "$JUNIPER_TS_IP" "juniper Tailscale" "success" >/dev/null
        test_dns "$EXTERNAL_DOMAIN" "$JUNIPER_TS_IP" "juniper Tailscale" "success" >/dev/null
      else
        print_fail "Cannot reach juniper via Tailscale ($JUNIPER_TS_IP)"
        print_explain "juniper may be down or Tailscale routing issue"
      fi
    fi

    # PHASE 5: Disconnect Tailscale & Test Failback
    print_header "PHASE 5: Disconnecting Tailscale & Testing DNS Failback"

    print_info "Disconnecting Tailscale to test LAN fallback..."
    sudo ${pkgs.tailscale}/bin/tailscale down
    monitor_dns_transition "disconnect"
    sleep 1

    print_subheader "First DNS Query After Disconnect (May Timeout)"
    print_info "Testing first query after Tailscale disconnect - expect possible timeout..."
    start=$(date +%s.%N)
    first_result=$(test_dns "$EXTERNAL_DOMAIN" "127.0.0.1" "LAN Fallback (1st)" "success")
    end=$(date +%s.%N)
    first_duration=$(echo "$end - $start" | ${pkgs.bc}/bin/bc)

    if (( $(echo "$first_duration > 4" | ${pkgs.bc}/bin/bc -l) )); then
      print_info "First query took ''${first_duration}s (expected ~5s timeout during failover)"
      print_explain "systemd-resolved tries old DNS server first, then fails over"
    else
      print_pass "First query completed quickly (''${first_duration}s) - DNS already switched"
    fi

    print_subheader "Subsequent Queries (Should Be Fast)"
    print_info "Testing subsequent queries - should be instant..."
    for i in {1..3}; do
      test_dns "$EXTERNAL_DOMAIN2" "127.0.0.1" "LAN Fallback (#$i)" "success" >/dev/null
    done

    print_subheader "Internal Domain Resolution (LAN Fallback)"
    internal_result=$(test_dns "$INTERNAL_DOMAIN_ASPEN" "127.0.0.1" "LAN Fallback" "success")

    if [[ -z "$internal_result" ]] || [[ "$internal_result" == "TIMEOUT" ]]; then
      print_explain "Internal domains may fail if aspen is down and fallback is to public DNS (1.1.1.1/9.9.9.9)"
      print_explain "This is expected behavior - public DNS doesn't know *.opticon.dev domains"
    fi

    print_subheader "Verifying Fallback DNS Server"
    if command -v ${pkgs.systemd}/bin/resolvectl >/dev/null 2>&1; then
      final_dns=$(get_current_dns)

      if [[ "$final_dns" == "$ASPEN_LAN_IP" ]]; then
        print_pass "Successfully failed back to aspen LAN ($final_dns)"
      elif [[ "$final_dns" == "1.1.1.1" ]] || [[ "$final_dns" == "9.9.9.9" ]]; then
        print_warn "Failed back to public DNS ($final_dns)"
        print_explain "This happens when aspen is unreachable - internal domains will not resolve"
      else
        print_info "Fallback DNS: $final_dns"
      fi
    fi

    # PHASE 6: Advanced Diagnostics
    print_header "PHASE 6: Advanced Diagnostics"

    print_subheader "Full systemd-resolved Status"
    if command -v ${pkgs.systemd}/bin/resolvectl >/dev/null 2>&1; then
      ${pkgs.systemd}/bin/resolvectl status 2>/dev/null | head -40 | while IFS= read -r line; do
        echo "  $line"
      done
    else
      print_info "systemd-resolved not in use on this host"
    fi

    print_subheader "Comparing Pi-hole Responses"
    if ${pkgs.iputils}/bin/ping -c 1 -W 2 "$ASPEN_LAN_IP" >/dev/null 2>&1; then
      aspen_response=$(${pkgs.dnsutils}/bin/dig "$INTERNAL_DOMAIN_ASPEN" @"$ASPEN_LAN_IP" +short 2>/dev/null | head -1)
      print_info "aspen LAN response: $aspen_response"
    else
      print_warn "aspen not reachable via LAN"
    fi

    if is_tailscale_connected && ${pkgs.iputils}/bin/ping -c 1 -W 2 "$JUNIPER_TS_IP" >/dev/null 2>&1; then
      juniper_response=$(${pkgs.dnsutils}/bin/dig "$INTERNAL_DOMAIN_JUNIPER" @"$JUNIPER_TS_IP" +short 2>/dev/null | head -1)
      print_info "juniper Tailscale response: $juniper_response"
    fi

    # Restore initial Tailscale state
    print_header "CLEANUP: Restoring Initial State"

    if [[ "$INITIAL_TS_STATE" == "connected" ]] && ! is_tailscale_connected; then
      print_info "Reconnecting Tailscale to restore initial state..."
      if sudo ${pkgs.tailscale}/bin/tailscale up --accept-routes >/dev/null 2>&1; then
        print_pass "Tailscale reconnected successfully"
      else
        print_warn "Failed to reconnect Tailscale - run 'tup' manually"
      fi
    elif [[ "$INITIAL_TS_STATE" == "disconnected" ]] && is_tailscale_connected; then
      print_info "Disconnecting Tailscale to restore initial state..."
      sudo ${pkgs.tailscale}/bin/tailscale down
      print_pass "Tailscale disconnected"
    else
      print_pass "No state change needed"
    fi

    # Final Summary
    print_header "TEST SUMMARY"

    echo -e "  ''${GREEN}Passed:''${RESET}  $TESTS_PASSED"
    echo -e "  ''${RED}Failed:''${RESET}  $TESTS_FAILED"
    echo -e "  ''${YELLOW}Warnings:''${RESET} $TESTS_WARNING"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
      echo -e "  ''${GREEN}''${BOLD}✓ All critical tests passed!''${RESET}"
    else
      echo -e "  ''${RED}''${BOLD}✗ Some tests failed - review output above''${RESET}"
    fi

    echo -e "\n''${CYAN}''${BOLD}Test Flow Summary:''${RESET}"
    echo -e "  1. Forced Tailscale OFF → Baseline LAN DNS tests"
    echo -e "  2. Connected Tailscale → Monitored DNS transition to MagicDNS"
    echo -e "  3. Tested resolution via Tailscale (MagicDNS → juniper Pi-hole)"
    echo -e "  4. Disconnected Tailscale → Monitored DNS failback transition"
    echo -e "  5. Tested failback behavior (first query timeout, subsequent fast)"
    echo -e "  6. Restored initial Tailscale state"
    echo ""
    echo -e "''${CYAN}''${BOLD}Key Architecture Points (from README.md):''${RESET}"
    echo -e "  • Tailscale ON: DNS via 100.100.100.100 (MagicDNS) → juniper Pi-hole"
    echo -e "  • Tailscale OFF: DNS via DHCP → aspen LAN ($ASPEN_LAN_IP) or fallback (1.1.1.1/9.9.9.9)"
    echo -e "  • DNS transition: systemd-resolved switches within 0.5-10s of Tailscale state change"
    echo -e "  • First query after failback: May take ~5s if stale DNS server still cached"
    echo -e "  • Subsequent queries: <0.1s (systemd-resolved learns new Current DNS Server)"
    echo -e "  • Internal domains fail when using public fallback DNS (expected behavior)"
    echo ""
  '';

in

{
  environment.systemPackages = [ networkTestScript ];
}
