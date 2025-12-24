{
  pkgs,
  lib,
  ...
}:

{

  services.printing = {
    enable = true; # automatically opens firewall port 661
    package = pkgs.pkgs-2505.cups; # pin to 25.05 version of cups (2.4.14)
    startWhenNeeded = true; # prevent CUPS running as a daemon and only come alive when print request comes in
    drivers = [ pkgs.pkgs-2505.canon-cups-ufr2 ]; # canon printer drivers from same nixpkgs version for ABI compatibility
    #drivers = [ pkgs.canon-cups-ufr2 ];
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