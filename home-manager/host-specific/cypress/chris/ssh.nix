{ 
  pkgs,
  config,
  configVars,
  ... 
}: 

{

  programs.ssh = {
    enable = true;
    matchBlocks = {
      #"thinkpad-tailscale" = {
      #  hostname = "${configVars.thinkpadTailscaleIp}";
      #  user = "chris";
      #  port = 22;
      #};
    };
  };

}