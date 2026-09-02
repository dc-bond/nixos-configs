{ 
  pkgs, 
  ... 
}: 

# baseline admin cli present on every host — these carry no configuration of their own, so
# they lived as an identical copy-pasted block in each host's configuration.nix and drifted
# (jq missing on kauri/alder, zip missing on thinkpad). centralised here so every host gets
# the same set; host-specific tools still belong in that host's configuration.nix
{

  environment.systemPackages = with pkgs; [
    age # encryption tool
    mkpasswd # password hashing tool
    dig # dns lookup tool
    wget # download tool
    rsync # sync tool
    jq # json parser tool
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
    nix-tree # table view of package dependencies
    ethtool # network tools
    inetutils # more network tools like telnet
    zip # zip compression utility
    unzip # utility to unzip directories
    btop # system monitor
    tmux # terminal multiplexer for persistent sessions
    nmap # network scanning
  ];

}
