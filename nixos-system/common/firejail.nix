{ 
  pkgs,
  lib,
  configVars,
  ... 
}: 

{

  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      librewolf = {
        executable = pkgs.writeShellScript "librewolf-ephemeral" ''
          #!/usr/bin/env bash
          set -e
          
          echo "Setting up Tailscale exit node..."
          sudo tailscale up --ssh --accept-routes --exit-node=${configVars.juniperTailscaleIp}
          
          echo "Launching LibreWolf..."
          ${lib.getBin pkgs.librewolf}/bin/librewolf --private-window "https://ipleak.net" "$@"
          
          echo "LibreWolf closed. Tailscale deactivation initiated ..."
          sudo tailscale up --ssh --accept-routes --exit-node=${configVars.aspenTailscaleIp}
          echo "Done."
        '';
        profile = pkgs.writeText "librewolf-ephemeral.profile" ''
          include ${pkgs.firejail}/etc/firejail/librewolf.profile
          tmpfs ~/.librewolf
          tmpfs ~/.cache/librewolf
        '';
      };
    };
  };

}