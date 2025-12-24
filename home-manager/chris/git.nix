{ 
  pkgs,
  configVars, 
  ... 
}: 

{

  programs.git = {
    enable = true;
    settings = {
      user.name = "dc-bond";
      user.email = configVars.users.chris.email;
      pull.rebase = false;
      init.defaultBranch = "main";
    };
    signing = {
      signByDefault = true;
      format = "openpgp";
      key = configVars.users.chris.email;
    };
  };

}
