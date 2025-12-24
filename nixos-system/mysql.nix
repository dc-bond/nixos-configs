{
  pkgs,
  ...
}: 

{

  services = {

    mysql = {
      enable = true;
      package = pkgs.mariadb_1011; # LTS with security updates through 2028, switch to 118 newer LTS 2029 when ready to migrate versions
    };

    mysqlBackup = { # mysql database backup
      enable = true;
    };

  };

}