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

}