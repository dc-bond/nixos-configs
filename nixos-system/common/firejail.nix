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
          
          cleanup() {
            echo "LibreWolf closed. Deactivating remote Tailscale exit node ..."
            sudo ${pkgs.tailscale}/bin/tailscale up --ssh --accept-routes --exit-node=${configVars.aspenTailscaleIp} 2>/dev/null || true
            echo "Done."
          }
          trap cleanup EXIT
          
          echo "Activating remote Tailscale exit node ..."
          sudo ${pkgs.tailscale}/bin/tailscale up --ssh --accept-routes --exit-node=${configVars.juniperTailscaleIp}
          
          echo "Launching LibreWolf ..."
          exec ${lib.getBin pkgs.librewolf}/bin/librewolf --private-window "https://ipleak.net" "$@"
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