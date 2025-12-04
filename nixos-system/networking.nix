{ 
  lib, 
  config, 
  configVars,
  pkgs, 
  ... 
}: 

let
  hostData = configVars.hosts.${config.networking.hostName};
  hasWifi = hostData.networking.wifiInterface != null;
  hasDock = hostData.networking.dockInterface != null;
  hasEthernet = hostData.networking.ethernetInterface != null;
in

{

  services.resolved = {
    enable = hostData.networking.useResolved;
    llmnr = "false";
  };

  environment.etc."resolv.conf" = lib.mkIf (!hostData.networking.useResolved) { # if not using systemd-resolved, than manually create resolv.conf
    text = ''
      nameserver 127.0.0.1
      nameserver 1.1.1.1
    '';
  };

  networking = {
    useDHCP = false; # disable dhcpcd in favor of systemd-networkd below
    firewall.enable = true;
    wireless.iwd = lib.mkIf hasWifi {
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
    } // lib.optionalAttrs hasEthernet {
      "10-ethernet-builtin" = {
        matchConfig.Name = hostData.networking.ethernetInterface;
        networkConfig.DHCP = "ipv4";
        dhcpV4Config.RouteMetric = 200;
        dhcpV6Config.RouteMetric = 200;
        linkConfig.RequiredForOnline = "no";
      };
    } // lib.optionalAttrs hasDock {
      "20-ethernet-dock" = {
        matchConfig.Name = hostData.networking.dockInterface;
        networkConfig.DHCP = "ipv4";
        dhcpV4Config.RouteMetric = 100;
        dhcpV6Config.RouteMetric = 100;
        linkConfig.RequiredForOnline = "no";
      };
    } // lib.optionalAttrs hasWifi {
      "30-wifi" = {
        matchConfig.Name = hostData.networking.wifiInterface;
        networkConfig = {
          DHCP = "ipv4";
          IgnoreCarrierLoss = "3s";
        };
        dhcpV4Config.RouteMetric = 300;
        dhcpV6Config.RouteMetric = 300;
        linkConfig.RequiredForOnline = "no";
      };
    };
  };

  environment.systemPackages = lib.optional hasWifi
    (pkgs.writeShellScriptBin "wifi" ''
      set -euo pipefail

      INTERFACE="${hostData.networking.wifiInterface}"
      
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "        WiFi Connection Helper"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      
      if ! systemctl is-active --quiet iwd; then
        echo "❌ Error: iwd service is not running"
        exit 1
      fi

      echo "🔍 Scanning for WiFi networks..."
      ${pkgs.iwd}/bin/iwctl station "$INTERFACE" scan
      sleep 2
      
      echo ""
      echo ""
      ${pkgs.iwd}/bin/iwctl station "$INTERFACE" get-networks
      echo ""
      echo ""
      
      read -p "Type the WiFi network name: " SSID
      
      if [[ -z "$SSID" ]]; then
        echo "❌ Error: Network name cannot be empty"
        exit 1
      fi
      
      echo ""
      echo "🔗 Connecting to '$SSID'..."
      
      if ${pkgs.iwd}/bin/iwctl station "$INTERFACE" connect "$SSID"; then
        echo ""
        echo "Successfully connected to '$SSID'!"
        sleep 1
        
        echo ""
        echo "Connection details:"
        echo ""
        ${pkgs.iwd}/bin/iwctl station "$INTERFACE" show
        
        echo ""
        SIGNAL=$(${pkgs.iwd}/bin/iwctl station "$INTERFACE" show 2>/dev/null | grep "AverageRSSI" | awk '{print $2}')
        if [[ -n "$SIGNAL" ]]; then
          RSSI_NUM=''${SIGNAL}
          if (( RSSI_NUM >= -50 )); then
            QUALITY="excellent - very fast & reliable"
          elif (( RSSI_NUM >= -60 )); then
            QUALITY="good - reasonably fast and reliable"
          elif (( RSSI_NUM >= -70 )); then
            QUALITY="fair - browsing ok, streaming/video calls may buffer"
          else
            QUALITY="weak - browsing slow, may disconnect"
          fi
          echo "📡 Signal Strength: $SIGNAL dBm ($QUALITY)"
        fi
      else
        echo ""
        echo "❌ Failed to connect to '$SSID'"
        echo "Please check the network name and password, then try again"
        exit 1
      fi
    '');

}