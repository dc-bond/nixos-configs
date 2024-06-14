{ config, pkgs, ... }: 

{

# vscodium
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
  };

}
