{ pkgs, ... }: 

{

  services.printing = {
    enable = true;
    browsing = true;
    #drivers = [ pkgs.canon-cups-ufr2 ]; # provides canon printer drivers
  };

  #canon-cups-ufr2.overrideAttrs (prev: {
  #  src = prev.src.override {
  #    url = "https://pdisp01.c-wss.com/gdl/WWUFORedirectTarget.do?id=MDEwMDAwOTIzNjE4&cmp=ABR&lang=EN";
  #    hash = "sha256-HvuRQYqkHRCwfajSJPridDcADq7VkYwBEo4qr9W5mqA="; 
  #  };
  #})

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

  #services.printing.cups-pdf = {
  #  enable = true;
  #};

}