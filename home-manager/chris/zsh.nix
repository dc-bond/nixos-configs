{ 
  config, 
  configVars,
  osConfig,
  lib, 
  pkgs, 
  ... 
}: 

{
  

  programs.zsh = {
    initContent = lib.optionalString (lib.elem osConfig.networking.hostName ["cypress" "thinkpad"]) # added to zsh interactive shell (.zshrc)
    ''
      librewolf-private() {
        echo "launching LibreWolf..."
        librewolf --private-window "https://ipleak.net" "$@"
      }
    '';
    shellAliases = {
    } // lib.optionalAttrs (lib.elem osConfig.networking.hostName ["cypress" "thinkpad"]) {
      ledger = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/bond-ledger/ && nix develop --command codium . && cd ~";
      finplannerdev = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/finplanner/ && nix develop";
      chrisworkoutdev = "cd /home/chris/nextcloud-client/Personal/misc/chris-workouts/ && nix develop";
      danielleworkoutdev = "cd /home/chris/nextcloud-client/Personal/misc/danielle-workouts/ && nix develop";
      cloneconfigs = "cd $HOME/nextcloud-client/Personal/nixos && git clone https://github.com/dc-bond/nixos-configs";
      configs = "cd $HOME/nextcloud-client/Personal/nixos/nixos-configs";
      flakeupdate= "(cd $HOME/nextcloud-client/Personal/nixos/nixos-configs && nix flake update)";
    } // lib.optionalAttrs (osConfig.networking.hostName == "cypress") {
      storage = "cd /storage/WD-WX21DC86RU3P ; ls";
    } // lib.optionalAttrs (osConfig.networking.hostName == "aspen") {
      storage = "cd /storage/WD-WCC7K4RU947F ; ls";
    };
  };

}