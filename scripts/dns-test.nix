{
  pkgs,
  lib,
  config,
  configVars,
  ...
}:

let

  dnsTestScript = pkgs.writeShellScriptBin "dns-test" ''
    #!/bin/bash

    echo "=== 1. DNS Configuration ==="
    cat /etc/resolv.conf
    echo ""

    echo "=== 2. Pi-hole Health ==="
    ${pkgs.docker}/bin/docker ps | grep -E "pihole|unbound"
    echo ""

    echo "=== 3. Local DNS Query ==="
    ${pkgs.bind}/bin/dig home-assistant.opticon.dev @127.0.0.1 +short
    echo ""

    echo "=== 4. Juniper Service Query ==="
    ${pkgs.bind}/bin/dig grafana.opticon.dev @127.0.0.1 +short
    echo ""

    echo "=== 5. Ad Blocking Test ==="
    ${pkgs.bind}/bin/dig doubleclick.net @127.0.0.1 +short
    echo ""

    echo "=== 6. Tailscale Status ==="
    ${pkgs.tailscale}/bin/tailscale status | head -n 3
    echo ""

    echo "=== 7. Query via LAN IP ==="
    ${pkgs.bind}/bin/dig photos.opticon.dev @192.168.1.2 +short
    echo ""

    echo "=== 8. Query via Tailscale IP ==="
    ${pkgs.bind}/bin/dig photos.opticon.dev @100.68.250.108 +short
    echo ""

    echo "=== 9. Compare with Juniper ==="
    echo "aspen:   $(${pkgs.bind}/bin/dig home-assistant.opticon.dev @127.0.0.1 +short)"
    echo "juniper: $(${pkgs.bind}/bin/dig home-assistant.opticon.dev @100.70.221.14 +short)"
  '';

in

{

  environment.systemPackages = with pkgs; [ dnsTestScript ];

}
