{ 
  pkgs,
  configVars, 
  ... 
}: 

{

  #home.packages = with pkgs; [ git ];

  programs.git = {
    enable = true;
    userName  = "dc-bond";
    userEmail = configVars.users.chris.email;
    signing = {
      signByDefault = true;
      format = "openpgp";
      key = configVars.users.chris.email;
    };
    extraConfig = {
      pull.rebase = false;
      init.defaultBranch = "main";
    };
  };

}
