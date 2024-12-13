{ 
  config, 
  pkgs, 
  configVars,
  ... 
}: 

{

  services = {

    zwave-js = {
      enable = true;
      port = 3000;
      #serialPort = "/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_d677b47b5594eb11ba3436703d98b6d1-if00-port0:/dev/zwave";
      #settings = {
      #};
    };

  };

}