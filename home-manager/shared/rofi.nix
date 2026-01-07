{ 
  config, 
  lib,
  pkgs, 
  ... 
}: 

{

  home.packages = [
    rofi-bluetooth # rofi bluetooth manager
    (pkgs.writeShellScriptBin "rofiPowerMenu" ''
      choice=$(printf "Lock\nSuspend\nLogout\nReboot\nShutdown" | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Power Menu")
      
      case "$choice" in
        Lock)
          ${pkgs.hyprlock}/bin/hyprlock
          ;;
        Suspend)
          systemctl suspend
          ;;
        Logout)
          # Detect which compositor is running and exit appropriately
          if pgrep -x "labwc" > /dev/null; then
            ${pkgs.labwc}/bin/labwc --exit
          elif pgrep -x "Hyprland" > /dev/null; then
            ${pkgs.hyprland}/bin/hyprctl dispatch exit
          fi
          ;;
        Reboot)
          systemctl reboot
          ;;
        Shutdown)
          systemctl poweroff
          ;;
      esac
    '')
  ];

  services.gpg-agent.pinentry.package = pkgs.pinentry-rofi;
  
  programs.rofi = {
    enable = true;
    package = pkgs.rofi.override {
      plugins = [ pkgs.rofi-calc ];
    };
    terminal = "${pkgs.alacritty}/bin/alacritty";
    font = "SauceCodePro Nerd Font 10";
    theme = 
    let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        accentcolor = mkLiteral "#95e6cb";
        backgroundcolor = mkLiteral "#1f2430f3";
        foregroundcolor = mkLiteral "#bfbab0";
        selectioncolor = mkLiteral "#fafafa";
        separatorcolor = mkLiteral "transparent";
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@foregroundcolor";
      };
      "#window" = {
        location = mkLiteral "center";
        background-color = mkLiteral "@backgroundcolor";
        border-color = mkLiteral "@accentcolor";
        border = 0;
        border-radius = 0;
        padding = mkLiteral "16 14";
        width = mkLiteral "600px";
        y-offset = 29;
      };
      "#element" = {
        spacing = 2;
        padding = 8;
      };
      "#element.selected.normal" = {
        text-color = mkLiteral "@selectioncolor";
      };
      "#element.selected.active" = {
        text-color = mkLiteral "@selectioncolor";
      };
      "#inputbar" = {
        border = mkLiteral "none";
        children = map mkLiteral [ "prompt" "entry" ];
      };
      "#prompt" = {
        color = mkLiteral "@backgroundcolor";
        background-color = mkLiteral "@accentcolor";
        padding = mkLiteral "7 10 7 10";
      };
      "#entry" = {
        padding = mkLiteral "7 10 7 10";
      };
    };
    extraConfig = {
      #display-combi = "Combination Mode";
      display-run = "Run Scripts";
      display-drun = "Applications";
      display-ssh = "SSH";
    };
  };

}