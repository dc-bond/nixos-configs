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
    userEmail = configVars.userEmail;
    signing = {
      signByDefault = true;
      format = "openpgp";
      key = configVars.userEmail;
    };
    extraConfig = {
      pull.rebase = false;
      init.defaultBranch = "main";
    };
  };

}
