{
  pkgs,
  config,
  lib,
  configVars,
  ...
}: 

{

  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    listenAddress = "0.0.0.0";  # listen on all interfaces (tailscale included)
    enabledCollectors = [ 
      "systemd" # service states and health
      "processes" # process count, states, forks
      "interrupts" # irq statistics
      "tcpstat"  # tcp connection states
      "buddyinfo"  # memory fragmentation
    ];
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9100 ]; # open prometheus node exporter port on tailscale interface for monitoring-server data collection

}