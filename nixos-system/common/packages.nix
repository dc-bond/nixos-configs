{ 
  configLib,
  config, 
  pkgs, 
  ... 
}: 

{

  environment.systemPackages = with pkgs; [
    (import (configLib.relativeToRoot "scripts/common/hello-world.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/common/thinkpadDeploy.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/common/vm1Deploy.nix") { inherit pkgs config; })
    age # encryption tool
    sops # secrets management tool that can use different types of encryption (e.g. age, pgp, etc.)
    wget # download tool
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
    nvd # package version diff info for nix build operations
    nix-tree # table view of package dependencies
    ethtool # network tools
    unzip # utility to unzip directories
    git # git
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    btop # system monitor
    nmap # network scanning
  ];

}