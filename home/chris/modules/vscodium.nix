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
      "[nix]"."editor.tabSize" = 2;
      #"extensions.experimental.affinity": {
      #    "asvetliakov.vscode-neovim": 1
      #},
      #"workbench.colorTheme": "Nord",
      #"workbench.iconTheme": "material-icon-theme",
      #"redhat.telemetry.enabled": false,
      #"git.enableSmartCommit": true,
      #"git.confirmSync": false,
      #"workbench.startupEditor": "none",
      #"window.restoreWindows": "one",
      #"git.autofetch": true,
      #"explorer.confirmDragAndDrop": false,
      "terminal.integrated.fontFamily" = "SauceCodePro NF";
      "editor.fontFamily" = "\"SauceCodePro NF\"";
      "editor.fontSize" = 15;
      #"editor.fontLigatures": false
    };
  };

}
