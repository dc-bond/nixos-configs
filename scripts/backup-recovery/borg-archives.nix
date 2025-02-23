{ 
  pkgs, 
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  listArchivesScript = pkgs.writeShellScriptBin "listArchives" ''
    #!/bin/bash

    # define available hosts
    HOSTS=("aspen", "cypress" "thinkpad")
    
    # display menu options for hosts
    echo "Select a host to recover:"
    for i in "''${!HOSTS[@]}"; do
      echo "$((i+1))) ''${HOSTS[$i]}"
    done
    
    # obtain target host from user
    read -p "Enter the number of your choice for a host: " CHOICE
    
    # validate host selection
    if [[ ! "$CHOICE" =~ ^[1-3]$ ]]; then
      echo "Error: Invalid selection."
      exit 1
    fi
   
    # set the selected host
    HOST="''${HOSTS[$((CHOICE-1))]}"

    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg list ${config.backups.borgDir}/$HOST
    '';

  infoArchivesScript = pkgs.writeShellScriptBin "infoArchives" ''
    #!/bin/bash

    # define available hosts
    HOSTS=("aspen", "cypress" "thinkpad")
    
    # display menu options for hosts
    echo "Select a host to recover:"
    for i in "''${!HOSTS[@]}"; do
      echo "$((i+1))) ''${HOSTS[$i]}"
    done
    
    # obtain target host from user
    read -p "Enter the number of your choice for a host: " CHOICE
    
    # validate host selection
    if [[ ! "$CHOICE" =~ ^[1-3]$ ]]; then
      echo "Error: Invalid selection."
      exit 1
    fi
   
    # set the selected host
    HOST="''${HOSTS[$((CHOICE-1))]}"
    
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgDir}/$HOST
    '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    listArchivesScript
    infoArchivesScript
  ];

}  