{ 
  pkgs, 
  ... 
}: 

# cli tooling reached for by hand and by claude code during interactive work — kept host-wide
# rather than behind 'nix-shell -p' so the tools are simply present, with no wrapper to remember
# on every invocation; most of these are already in the store as transitive dependencies, so
# listing them here costs symlinks rather than disk
{

  environment.systemPackages = with pkgs; [

    # scripting
    (python3.withPackages (ps: with ps; [
      requests # http client with sessions and retries
      pyyaml # yaml parsing
      openpyxl # read/write xlsx spreadsheets
    ])) # bundling the libraries here avoids falling back to 'nix-shell -p' for any non-stdlib import

    # document and image processing
    pandoc # convert between markdown, docx, html and pdf
    typst # pdf typesetting backend for pandoc, avoids pulling multi-gigabyte texlive
    poppler-utils # 'pdftotext', 'pdfinfo' and 'pdfimages' to extract and inspect pdf content
    qpdf # merge, split, rotate and decrypt pdfs
    ghostscript # pdf compression and flattening
    imagemagick # image conversion and resizing
    tesseract # ocr — 1.1 gib of language packs, but cached; '.override { enableLanguages = [ "eng" ]; }' trims it at the cost of a local source build

    # data and diagnostics
    yq-go # yaml equivalent of jq for home-assistant, zigbee2mqtt and compose files
    sqlite # inspect application databases during diagnostics
    ripgrep # fast recursive search
    lsof # which process holds a given file or port
    gh # github cli for the dc-bond repos

  ];

}
