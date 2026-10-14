{

  services.btrfs.autoScrub = {
    enable = true;
    interval = "Sun *-*-* 04:00:00"; # weekly sunday at 4am
  };

}
