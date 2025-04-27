{
  inputs, 
  ...
}: 

{

# unstable nixpkgs set (declared in the flake inputs) will be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  #kasmweb = final: _prev: {
  #  src = final.fetchurl {
  #    url = "https://kasm-static-content.s3.amazonaws.com/kasm_release_1.17.0.bbc15c.tar.gz";
  #    sha256 = "1zl64x59a38jwdxd2lf88hpj0ii1jkwbb0rpa4znpgmvq1686a5j";
  #  };
  #  version = "1.17.0";
  #};

}