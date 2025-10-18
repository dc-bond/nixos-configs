{
  pkgs,
  ...
}: 

{

  services = {

    postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
    };

    postgresqlBackup = { # postgres database backup
      enable = true;
    };

  };

}