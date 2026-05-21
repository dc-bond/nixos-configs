{
  inputs,
  ...
}:

{

# unstable nixpkgs set (declared in the flake inputs) will be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
        allowBroken = true;
      };
    };
  };

# 25.05 nixpkgs set for packages with bugs in current release, accessible through 'pkgs.pkgs-2505'
  nixpkgs-2505-packages = final: _prev: {
    pkgs-2505 = import inputs.nixpkgs-2505 {
      system = final.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
        allowBroken = true;
      };
    };
  };

# 22.05 nixpkgs set for legacy libraries dropped from newer releases (e.g. openssl_1_0_2 for IWD:EE), accessible through 'pkgs.pkgs-2205'
  nixpkgs-2205-packages = final: _prev: {
    pkgs-2205 = import inputs.nixpkgs-2205 {
      system = final.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
        allowBroken = true;
        permittedInsecurePackages = [ "openssl-1.0.2u" ];
      };
    };
  };

# to upgrade: update version + url below, run nix-prefetch-url to get new hash, then rebuild
  displaylink-pinned = final: prev: {
    linuxPackages = prev.linuxPackages // {
      displaylink = prev.linuxPackages.displaylink.overrideAttrs (old: { # overrides default so no need to explicitly specify
        version = "6.2";
        src = final.requireFile {
          name = "displaylink-620.zip";
          url = "https://www.synaptics.com/sites/default/files/exe_files/2025-09/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.2-EXE.zip";
          hash = "sha256-JQO7eEz4pdoPkhcn9tIuy5R4KyfsCniuw6eXw/rLaYE="; # only updated when pulling newer package, 'nix has to-sri --type sha256 <hash-from-prefetch-output>'
          message = ''
            DisplayLink 6.2 is pinned in overlays/default.nix
            Run this command on build host (e.g. cypress) to download and add to nix store:
            nix-prefetch-url --name displaylink-620.zip https://www.synaptics.com/sites/default/files/exe_files/2025-09/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.2-EXE.zip
          '';
        };
      });
    };
  };

}