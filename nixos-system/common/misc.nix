{ 
  pkgs, 
  ... 
}: 

{

  time.timeZone = "America/New_York"; # set timezone
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    earlySetup = true;
    font = "Lat2-Terminus16";
    #font = "${pkgs.source-code-pro}/share/consolefonts/???.gz"; # need to fix
    #packages = with pkgs; [ source-code-pro ];
    keyMap = "us";
  };

  systemd.extraConfig = "DefaultLimitNOFILE=2048"; # defaults to 1024 if unset

  #nix.settings.cores = 2;

}