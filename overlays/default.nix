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

# 21.05 nixpkgs set for legacy libraries dropped from newer releases (e.g. openssl_1_0_2 for IWD:EE), accessible through 'pkgs.pkgs-2105'
  nixpkgs-2105-packages = final: _prev: {
    pkgs-2105 = import inputs.nixpkgs-2105 {
      system = final.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
        allowBroken = true;
        permittedInsecurePackages = [ "openssl-1.0.2u" ];
      };
    };
  };

}
