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
      key = null;  # This tells git to use the key associated with user email
    };
    extraConfig = {
      pull.rebase = false;
      init.defaultBranch = "main";
    };
  };

}