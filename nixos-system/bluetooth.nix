{ pkgs, 
  ... 
}: 

{

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  systemd.services.bluetooth-power-on = {
    description = "Power on Bluetooth adapter";
    after = [ "bluetooth.service" ];
    requires = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bluez}/bin/bluetoothctl power on";
    };
  };

}