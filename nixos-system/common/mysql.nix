{
  pkgs,
  ...
}: 

{

  services = {

    mysql = {
      enable = true;
      package = pkgs.mariadb;
    };

    mysqlBackup = { # mysql database backup
      enable = true;
    };

  };

}