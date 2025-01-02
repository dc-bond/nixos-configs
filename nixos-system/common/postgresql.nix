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
      startAt = "*-*-* 01:00:00"; # daily starting at 1:00am
    };

  };

}