{ 
  pkgs,
  configVars, 
  ... 
}: 

{

  programs.git = {
    enable = true;
    userName  = "dc-bond";
    userEmail = configVars.userEmail;
    signing = {
      signByDefault = true;
      format = "openpgp";
      key = null;  # This tells git to use the key associated with programs.git.userEmail setting
    };
    extraConfig = {
      pull.rebase = false;
      init.defaultBranch = "main";
    };
  };

}