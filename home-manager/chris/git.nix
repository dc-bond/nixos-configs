{ 
  pkgs,
  configVars, 
  ... 
}: 

{

  home.packages = with pkgs; [ git ];

  programs.git = {
    enable = true;
    userName  = "dc-bond";
    userEmail = configVars.chrisEmail;
    signing = {
      signByDefault = true;
      format = "openpgp";
      key = configVars.chrisEmail;
    };
    extraConfig = {
      pull.rebase = false;
      init.defaultBranch = "main";
    };
  };

}
