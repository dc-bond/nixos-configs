{
  pkgs,
  ...
}:

{
  # moonlight game streaming client - no home-manager module exists; package only
  # connect to aspen at 192.168.1.2 (LAN) or 100.118.61.37 (tailscale)
  # on first connect add host manually: <ip>:47989
  home.packages = [ pkgs.moonlight-qt ];
}
