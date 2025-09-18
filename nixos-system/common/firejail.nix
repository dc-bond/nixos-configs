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
        executable = "${lib.getBin pkgs.librewolf}/bin/librewolf";
        profile = "${pkgs.firejail}/etc/firejail/librewolf.profile";
      };
    };
  };

}