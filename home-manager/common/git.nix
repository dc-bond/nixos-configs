{ 
  pkgs, 
  ... 
}: 

{

  programs.git = {
    enable = true;
    userName  = "dc-bond";
    userEmail = "chris@dcbond.com";
    extraConfig = {
      init.defaultBranch = "main";
      #commit.gpgsign = true;
      #gpg.format = "ssh";
      #gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      #user.signingkey = "~/.ssh/id_ed25519.pub";
    };
  };

}