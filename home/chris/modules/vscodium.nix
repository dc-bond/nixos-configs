{ config, pkgs, ... }: 

{

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      asvetliakov.vscode-neovim
      arcticicestudio.nord-visual-studio-code
      redhat.vscode-yaml
      pkief.material-icon-theme
      signageos.signageos-vscode-sops
      ms-python.python
    ];
    userSettings = {
      "files.autoSave" = "off";
      "redhat.telemetry.enabled" = false;
      "window.restoreWindows" = "one";
      "explorer.confirmDragAndDrop" = false;
      "extensions.experimental.affinity" = {
        "asvetliakov.vscode-neovim" = 1;
      };      
      "workbench" = {
        "colorTheme" = "Nord";
        "iconTheme" = "material-icon-theme";
        "startupEditor" = "none";
      };
      "git" = {
        "enableSmartCommit" = true;
        "confirmSync" = false;
        "autofetch" = true;
      };
      "terminal.integrated" = {
        "fontFamily" = "SauceCodePro NF";
        "copyOnSelection" = true;
        "cursorStyle" = "line";
        "cursorBlinking" = false;
      };
      "editor" = {
        "fontFamily" = "\"SauceCodePro NF\"";
        "fontSize" = 15;
        "fontLigatures" = false;
        "cursorBlinking" = "solid";
      };
    };
  };

}
