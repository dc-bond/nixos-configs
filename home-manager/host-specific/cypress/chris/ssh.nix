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
      "opticon-tailscale" = {
        hostname = "${configVars.opticonTailscaleIp}";
        user = "xixor";
        port = 22;
      };
      "thinkpad-tailscale" = {
        hostname = "${configVars.thinkpadTailscaleIp}";
        user = "chris";
        port = 22;
      };
    };
  };

}