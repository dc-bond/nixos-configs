{ 
  pkgs, 
  ... 
}: 

{

  services.printing = {
    enable = true;
    browsing = true;
    drivers = [ 
      #pkgs.canon-cups-ufr2 # canon printer drivers # try when 24.11 stable?
      pkgs.unstable.canon-cups-ufr2 # canon printer drivers
    ];
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
        };
      }
    ];
    ensureDefaultPrinter = "Canon-MF741C743C";
  };

}