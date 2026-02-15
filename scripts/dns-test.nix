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

  dnsTestScript = pkgs.writeShellScriptBin "dns-test" ''
    #!/bin/bash

    echo "=== 1. DNS Configuration ==="
    cat /etc/resolv.conf
    echo ""

    echo "=== 2. Pi-hole Health ==="
    ${pkgs.docker}/bin/docker ps | grep -E "pihole|unbound"
    echo ""

    echo "=== 3. Local DNS Query ==="
    dig home-assistant.opticon.dev @127.0.0.1 +short
    echo ""

    echo "=== 4. Juniper Service Query ==="
    dig grafana.opticon.dev @127.0.0.1 +short
    echo ""

    echo "=== 5. Ad Blocking Test ==="
    dig doubleclick.net @127.0.0.1 +short
    echo ""

    echo "=== 6. Tailscale Status ==="
    ${pkgs.tailscale}/bin/tailscale status
    echo ""

    echo "=== 7. Query via LAN IP ==="
    dig photos.opticon.dev @${aspenLanIp} +short
    echo ""

    echo "=== 8. Query via Tailscale IP ==="
    dig photos.opticon.dev @${aspenTailscaleIp} +short
    echo ""

    echo "=== 9. Compare with Juniper ==="
    echo "aspen:   $(dig home-assistant.opticon.dev @127.0.0.1 +short)"
    echo "juniper: $(dig home-assistant.opticon.dev @${juniperTailscaleIp} +short)"
  '';

in

{

  environment.systemPackages = with pkgs; [ dnsTestScript ];

}
