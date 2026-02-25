{
  config,
  configVars,
  ...
}:

let

  hostData = configVars.hosts.${config.networking.hostName};
  # use mountpoint for encrypted systems (btrfs scrub works on /dev/mapper/crypted via mountpoint)
  # use raw partition for unencrypted systems
  scrubDevice = if (hostData.hardware.diskEncryption or false)
    then "/persist"
    else "${hostData.hardware.disk0}-part2";

in

{

  services.btrfs.autoScrub = {
    enable = true;
    interval = "Sun *-*-* 04:00:00"; # weekly sunday at 4am
    fileSystems = [ scrubDevice ];
  };

}