{ 
  pkgs,
  lib,
  ... 
}: 

{

  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      librewolf = {
        #executable = "${lib.getBin pkgs.librewolf}/bin/librewolf";
        executable = pkgs.writeShellScript "librewolf-ephemeral" ''
          ${lib.getBin pkgs.librewolf}/bin/librewolf --private-window "$@"
        '';
        #profile = "${pkgs.firejail}/etc/firejail/librewolf.profile";
        profile = pkgs.writeText "librewolf-ephemeral.profile" ''
          include ${pkgs.firejail}/etc/firejail/librewolf.profile
          tmpfs ~/.librewolf
          tmpfs ~/.cache/librewolf
          tmpfs ~/.local/share/librewolf
        '';
      };
    };
  };

}