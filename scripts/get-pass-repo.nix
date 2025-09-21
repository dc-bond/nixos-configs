{ 
  pkgs,
}:

pkgs.writeShellScriptBin "getPassRepo" ''
  cd ~
  git clone git@github.com:dc-bond/.password-store.git
  touch ~/.password-store/.git/hooks/post-commit
  cat >> ~/.password-store/.git/hooks/post-commit << 'END'
  #!/bin/sh
  set -x
  git pull --rebase # get edits by other hosts
  git push # push the latest commit
  END
  chmod +x ~/.password-store/.git/hooks/post-commit
''