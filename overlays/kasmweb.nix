{
  inputs, 
  ...
}: 

final: prev: {
  kasmweb = prev.kasmweb.overrideAttrs (_: {
    src = prev.fetchurl {
      url = "https://kasm-static-content.s3.amazonaws.com/kasm_release_1.17.0.bbc15c.tar.gz";
      sha256 = "1zl64x59a38jwdxd2lf88hpj0ii1jkwbb0rpa4znpgmvq1686a5j";
    };
    version = "1.17.0";
  });
}