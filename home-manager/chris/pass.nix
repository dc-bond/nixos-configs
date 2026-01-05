{
  config,
  pkgs,
  ...
}:

{

  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
    };
    # wrap pass command to auto-clone password-store from GitHub on first use
    package = pkgs.symlinkJoin {
      name = "pass-with-auto-clone";
      paths = [ pkgs.pass ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/pass \
          --run '
            PASS_DIR="${config.home.homeDirectory}/.password-store"
            if [ ! -d "$PASS_DIR/.git" ]; then
              echo "Password-store not found. Cloning from GitHub..."
              ${pkgs.git}/bin/git clone git@github.com:dc-bond/.password-store.git "$PASS_DIR"

              # Set up post-commit hook for auto-sync
              cat > "$PASS_DIR/.git/hooks/post-commit" <<- "HOOK_END"
		#!/bin/sh
		set -x
		${pkgs.git}/bin/git pull --rebase # get edits by other hosts
		${pkgs.git}/bin/git push # push the latest commit
		HOOK_END
              chmod +x "$PASS_DIR/.git/hooks/post-commit"
              echo "Password-store cloned and configured successfully"
            fi
          '
      '';
    };
  };

}