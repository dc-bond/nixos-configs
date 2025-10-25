{ 
  lib, 
  config, 
  pkgs, 
  ... 
}: 

{

  services.resolved = {
    enable = lib.elem config.networking.hostName ["juniper" "thinkpad" "cypress"]; # use systemd-resolved for DNS functionality, defaults to "false" (e.g. for aspen)
    llmnr = "false"; # disable link-local multicast name resolution
  };

  environment.etc."resolv.conf" = lib.mkIf (config.networking.hostName == "aspen") { # networking.resolvconf.enable automatically sets itself to "false" (e.g. for aspen) if environment.etc."resolv.conf" defined
    text = ''
      nameserver 127.0.0.1
      nameserver 1.1.1.1
    '';
  };

  networking = {
    useDHCP = false; # disable default dhcpcd networking backend in favor of systemd-networkd enabled below
    firewall.enable = true;
    wireless.iwd = lib.mkIf (config.networking.hostName == "thinkpad") {
      enable = true;
      settings = {
        IPv6.Enabled = false;
        Settings = {
          AutoConnect = false;
          AlwaysRandomizeAddress = false;
        };
      };
    };
  };

  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
  
  systemd.network = {
    enable = true;
    networks = {
      "05-loopback" = {
        matchConfig.Name = "lo";
        linkConfig.RequiredForOnline = "no";
      };
      "10-ethernet-builtin" = {
        matchConfig.Name = 
          if config.networking.hostName == "thinkpad" then "enp0s31f6"
          else if config.networking.hostName == "aspen" then "enp4s0"
          else "enp1s0"; # juniper and cypress fallback
        networkConfig.DHCP = "ipv4";
        dhcpV4Config.RouteMetric = 200;
        dhcpV6Config.RouteMetric = 200;
        linkConfig.RequiredForOnline = "no";
      };
    } // lib.optionalAttrs (config.networking.hostName == "thinkpad") {
      "20-ethernet-dock" = {
        matchConfig.Name = "enp0s20f0u2u1u2";
        networkConfig.DHCP = "ipv4";
        dhcpV4Config.RouteMetric = 100;
        dhcpV6Config.RouteMetric = 100;
        linkConfig.RequiredForOnline = "no";
      };
      "30-wifi" = {
        matchConfig.Name = "wlan0";
        networkConfig = {
          DHCP = "ipv4";
          IgnoreCarrierLoss = "3s"; # avoid re-configuring interface when wireless roaming between APs
        };
        dhcpV4Config.RouteMetric = 300;
        dhcpV6Config.RouteMetric = 300;
        linkConfig.RequiredForOnline = "no";
      };
    };
  };

  environment.systemPackages = lib.mkIf (config.networking.hostName == "thinkpad") [
    (pkgs.writeShellScriptBin "connect-wifi" ''
      set -euo pipefail

      INTERFACE="wlan0"
      
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "        WiFi Connection Helper"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      
      # Check if iwd is running
      if ! systemctl is-active --quiet iwd; then
        echo "❌ Error: iwd service is not running"
        exit 1
      fi

      # Scan for networks
      echo "🔍 Scanning for WiFi networks..."
      ${pkgs.iwd}/bin/iwctl station "$INTERFACE" scan
      sleep 2
      
      # Show available networks with signal strength
      echo ""
      echo "Available networks (signal strength shown as bars):"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      ${pkgs.iwd}/bin/iwctl station "$INTERFACE" get-networks
      echo ""
      echo "Signal guide: ▂▄▆█ = Excellent | ▂▄▆_ = Good | ▂▄__ = Fair | ▂___ = Weak"
      echo ""
      
      # Get network name from user (bash syntax)
      read -p "Enter the WiFi network name (SSID): " SSID
      
      if [[ -z "$SSID" ]]; then
        echo "❌ Error: Network name cannot be empty"
        exit 1
      fi
      
      # Connect to network
      echo ""
      echo "🔗 Connecting to '$SSID'..."
      
      if ${pkgs.iwd}/bin/iwctl station "$INTERFACE" connect "$SSID"; then
        echo ""
        echo "✅ Successfully connected to '$SSID'!"
        sleep 1
        
        # Show detailed connection info including signal strength
        echo ""
        echo "Connection details:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ${pkgs.iwd}/bin/iwctl station "$INTERFACE" show
        
        # Extract and highlight signal strength
        echo ""
        SIGNAL=$(${pkgs.iwd}/bin/iwctl station "$INTERFACE" show | grep -i "rssi" | awk '{print $2}')
        if [[ -n "$SIGNAL" ]]; then
          # Convert RSSI to percentage and quality description
          RSSI_NUM=''${SIGNAL}
          if (( RSSI_NUM >= -50 )); then
            QUALITY="Excellent 📶"
          elif (( RSSI_NUM >= -60 )); then
            QUALITY="Good 📶"
          elif (( RSSI_NUM >= -70 )); then
            QUALITY="Fair 📶"
          else
            QUALITY="Weak 📶"
          fi
          echo "📡 Signal Strength: $SIGNAL dBm ($QUALITY)"
        fi
      else
        echo ""
        echo "❌ Failed to connect to '$SSID'"
        echo "Please check the network name and password, then try again"
        exit 1
      fi
    '')
  ];

}