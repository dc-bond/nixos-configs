{
  pkgs,
  ...
}:

{

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      extensions = (with pkgs.vscode-extensions; [
        arcticicestudio.nord-visual-studio-code
        pkief.material-icon-theme
      ]) ++ [
        pkgs.unstable.vscode-extensions.anthropic.claude-code # pinned to unstable for parity with claude-code CLI
      ];
      userSettings = {
        "files.autoSave" = "off";
        "redhat.telemetry.enabled" = false;
        "window.restoreWindows" = "one";
        "claudeCode.useTerminal" = true;
        "explorer" = {
          "confirmDragAndDrop" = false;
          "confirmDelete" = false;
        };
        "extensions" = {
          "autoCheckUpdates" = false;
          "autoUpdate" = false;
        };
        "workbench" = {
          "colorTheme" = "Nord";
          "iconTheme" = "material-icon-theme";
          "startupEditor" = "none";
        };
        "terminal.integrated" = {
          "fontFamily" = "SauceCodePro NF";
          "copyOnSelection" = true;
          "cursorStyle" = "block";
          "cursorBlinking" = false;
          "defaultProfile.linux" = "zsh";
        };
        "editor" = {
          "fontFamily" = "\"SauceCodePro NF\"";
          "fontSize" = 15;
          "fontLigatures" = false;
          "cursorStyle" = "line";
          "cursorBlinking" = "solid";
        };
      };
    };
  };

}
