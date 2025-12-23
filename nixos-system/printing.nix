{ 
  pkgs, 
  ... 
}: 

{

  services.printing = {
    enable = true; # automatically opens firewall port 661
    #browsing = false;
    startWhenNeeded = false; # keep CUPS running as a daemon: prevents firefox freeze waiting for on-demand CUPS startup in 25.11
    drivers = [ pkgs.canon-cups-ufr2 ]; # canon printer drivers
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Canon-MF741C743C"; # must manually set color mode to black & white?
        location = "3rd Floor";
        deviceUri = "socket://192.168.4.17";
        model = "CNRCUPSMF741CZK.ppd";
        ppdOptions = {
          PageSize = "Letter";
          CNColorMode = "mono"; # set default to black/white, other option is "color"
        };
      }
    ];
    ensureDefaultPrinter = "Canon-MF741C743C";
  };

}