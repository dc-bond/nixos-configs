{ 
  pkgs, 
  pkgs-unstable, 
  ... 
  }: 

#let
#  pkgs = import (builtins.fetchTarball {
#    url = "https://github.com/NixOS/nixpkgs/archive/05bbf675397d5366259409139039af8077d695ce.tar.gz";
#    #sha256 = "aea44d2f19311078531268063ba559e578c94e5e";
#    sha256 = "1r26vjqmzgphfnby5lkfihz6i3y70hq84bpkwd43qjjvgxkcyki0";
#  }) {};
#  myPkg = pkgs.canon-cups-ufr2;
#in {

{

  services.printing = {
    enable = true;
    browsing = true;
    drivers = [ pkgs-unstable.canon-cups-ufr2 ]; # provides canon printer drivers
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

  #services.printing.cups-pdf = {
  #  enable = true;
  #};

}