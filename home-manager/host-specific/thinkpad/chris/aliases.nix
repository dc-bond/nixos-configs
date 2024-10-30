{ 
  pkgs, 
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbthink = "rebuildLocalThinkpad";
      rbvm1 = "rebuildRemoteVm1";
      rbaspen = "rebuildRemoteAspen";
      getnets = "iwctl station wlan0 get-networks";
      flakeupdate = "sudo nix flake update ~/nixos-configs";
      wgup = "sudo networkctl up wg0";
      wgdn = "sudo networkctl down wg0";
      wglogon = "echo module wireguard +p | sudo tee /sys/kernel/debug/dynamic_debug/control";
      wglogs = "journalctl -ekf";
    };
  };

}