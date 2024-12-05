{ 
  pkgs, 
  config 
}:

pkgs.writeShellScriptBin "restore-backup" 
''
  runuser -u postgres -- psql -U postgres -d template1 -c "DROP DATABASE \"nextcloud\";"
  runuser -u postgres -- psql -U postgres -d template1 -c "CREATE DATABASE \"nextcloud\";"
  gunzip 
  runuser -u postgres -- psql -U postgres -d nextcloud -f nextcloud.sql
''