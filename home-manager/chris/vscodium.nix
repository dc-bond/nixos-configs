{
  config,
  pkgs,
  ...
}:

{

  #sops.secrets.anthropicApiKey = {};

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      extensions = (with pkgs.vscode-extensions; [
        bbenoist.nix
        asvetliakov.vscode-neovim
        arcticicestudio.nord-visual-studio-code
        redhat.vscode-yaml
        pkief.material-icon-theme
        signageos.signageos-vscode-sops
        ms-python.python
        arrterian.nix-env-selector
        # manually install 'Beancount' from extension marketplace
      ]) ++ [
        pkgs.unstable.vscode-extensions.anthropic.claude-code # pinned to unstable for parity with claude-code CLI
      ];
      userSettings = {
        "files.autoSave" = "off";
        "redhat.telemetry.enabled" = false;
        "window.restoreWindows" = "one";
        "claudeCode.useTerminal" = true; # only enables the Ctrl+Escape "open in terminal" shortcut; New Session button stays native UI
        "explorer" = {
          "confirmDragAndDrop" = false;
          "confirmDelete" = false;
        };
        "extensions" = {
          "autoCheckUpdates" = false;
          "autoUpdate" = false;
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
          "confirmSync" = false;
          "autofetch" = true;
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
          "defaultProfile.linux" = "zsh";
        };
        "editor" = {
          "fontFamily" = "\"SauceCodePro NF\"";
          "fontSize" = 15;
          "fontLigatures" = false;
          "cursorStyle" = "line";
          "cursorBlinking" = "solid";
        };
        "remote" = {
          "autoForwardPortsSource" = "hybrid";
        };
        "remote.SSH" = {
          "showLoginTerminal" = true;
          "useLocalServer" = false;
          "configFile" = "/home/chris/.ssh/config";
          "autoForwardPorts" = false;
          "autoForwardPortsSource" = "hybrid";
          "serverInstallPath" = {
            "cypress" = "~/.vscodium-server";
          };
        };
      };
    };
  };

}