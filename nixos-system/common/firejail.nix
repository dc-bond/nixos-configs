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
        executable = "${lib.getBin pkgs.librewolf}/bin/librewolf";
        profile = pkgs.writeText "librewolf-private.profile" ''
          include ${pkgs.firejail}/etc/firejail/librewolf.profile
          tmpfs ~/.librewolf
          tmpfs ~/.cache/librewolf
        '';
      };
    };
  };
}