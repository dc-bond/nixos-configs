{ 
  config, 
  pkgs, 
  configVars,
  configLib,
  ... 
}: 

{

  sops.secrets = {
    zwaveSecurityKeys = {
      sopsFile = configLib.relativeToRoot "hosts/cypress/zwave-security-keys.json";
      format = "json";
    };
  };

  sops.secrets.github_token = {
    # The sops file can be also overwritten per secret...
    sopsFile = ./other-secrets.json;
    # ... as well as the format
    format = "json";
  };

  services = {

    zwave-js = {
      enable = true;
      port = 3000;
      serialPort = "/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_d677b47b5594eb11ba3436703d98b6d1-if00-port0:/dev/zwave";
      secretsConfigFile = "${config.sops.secrets.zwaveSecurityKeys.path}";
      #settings = {
      #};
    };

  };

}