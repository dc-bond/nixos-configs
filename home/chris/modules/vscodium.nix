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
      "explorer" = {
        "confirmDragAndDrop" = false;
        "confirmDelete" = false;
      };
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
        #"enableCommitSigning" = true;
        "confirmSync" = false;
        "autofetch" = false;
        "useIntegratedAskPass" = true;
      };
      "github" = {
        "gitProtocol" = "ssh";
      };
      "terminal.integrated" = {
        "fontFamily" = "SauceCodePro NF";
        "copyOnSelection" = true;
        "cursorStyle" = "block";
        "cursorBlinking" = false;
      };
      "editor" = {
        "fontFamily" = "\"SauceCodePro NF\"";
        "fontSize" = 15;
        "fontLigatures" = false;
        "cursorStyle" = "block";
        "cursorBlinking" = "solid";
      };
      "remote.SSH" = {
        "showLoginTerminal" = true;
        "useLocalServer" = false;
        "configFile" = "/home/chris/.ssh/config";
      };
    };
  };

}
