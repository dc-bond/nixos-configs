{
  pkgs,
  ...
}: 

{

  services = {

    postgresql = {
      enable = true;
      package = pkgs.postgresql_17; # current LTS with security fixes through Nov 2029
    };

    postgresqlBackup = { # postgres database backup
      enable = true;
    };

  };

}