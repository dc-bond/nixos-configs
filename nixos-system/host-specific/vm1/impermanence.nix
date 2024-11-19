{ 
  inputs,
  configVars,
  ... 
}: 

{

  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  environment.persistence."/persist" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      #{ directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
    ];
    files = [
      "/etc/machine-id"
      #{ file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
    ];
    #users.${configVars.userName} = {
    #  directories = [
    #    #"Downloads"
    #    #"Documents"
    #    #{ directory = ".gnupg"; mode = "0700"; }
    #    #{ directory = ".ssh"; mode = "0700"; }
    #    #{ directory = ".nixops"; mode = "0700"; }
    #    #{ directory = ".local/share/keyrings"; mode = "0700"; }
    #    #".local/share/direnv"
    #  ];
    #  #files = [
    #  #  ".screenrc"
    #  #];
    #};
  };

}