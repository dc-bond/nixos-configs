{ 
  pkgs, 
  config, 
  lib, 
  configVars,
  ... 
}:

{

  services.fail2ban = {
    # global settings
    enable = true;
    maxretry = 5;
    bantime = "1h";
    extraPackages = [ pkgs.ipset ];
    banaction = "iptables-ipset-proto6-allports"; # use ipset to ban ipv4 and ipv6 on all ports for offending ip targeting a specific port
    banaction-allports = "iptables-ipset-proto6-allports"; # use ipset to ban ipv4 and ipv6 on all ports for offending ip targeting all ports
    bantime-increment = { # incremental ban time for repeat offendending ips
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # max one week
      overalljails = true; # calculate bandtime based on all jail violations
    };
    ignoreIP = [ # whitelist local networks to prevent lockouts
      "127.0.0.1/8"
      "192.168.0.0/16"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "100.64.0.0/10" # tailscale CGNAT range
    ];
    # configs and overrides for specific services (aka "jails")
    jails = {

      sshd.settings = {
        enabled = true;
        maxretry = 3; # stricter than global 5
        findtime = "5m"; # look for patters over 5 minutes
        backend = "systemd";
      };

      traefik-auth.settings = {
        enabled = true;
        filter = "traefik-auth";
        journalmatch = "_SYSTEMD_UNIT=traefik.service";
        maxretry = 5; # allow more retries for legitimate users
        bantime = "2h"; # longer ban for persistent attackers
        findtime = "10m"; # look for patterns over 10 minutes
        backend = "systemd";
      };
      
      traefik-scan.settings = {
        enabled = true;
        filter = "traefik-scan";
        journalmatch = "_SYSTEMD_UNIT=traefik.service";
        maxretry = 2; # very low tolerance for scanning
        bantime = "4h"; # long ban for reconnaissance attempts
        findtime = "5m"; # quick detection window
        backend = "systemd";
      };
      
      traefik-flood.settings = {
        enabled = true;
        filter = "traefik-flood";
        journalmatch = "_SYSTEMD_UNIT=traefik.service";
        maxretry = 100; # allow reasonable request volume
        bantime = "30m"; # shorter ban for potential false positives
        findtime = "2m"; # short window to detect rapid requests
        backend = "systemd";
      };

    };
    
  };
    
  # custom filter definitions
  environment.etc = {

    # traefik authentication failures (401/403) # use .local extension to override default traefik-auth filter in filter.d that ships with fail2ban
    "fail2ban/filter.d/traefik-auth.local".text = ''
      [Definition]

      # match 401 (unauthorized) and 403 (forbidden) responses
      failregex = ^<HOST> - - \[.*\] "(GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH).*HTTP/\d\.\d" (401|403) .*$
      
      # ignore health checks and authelia verify endpoints
      ignoreregex = ^.*"(GET|POST) /api/verify.*$
                    ^.*"GET /_health.*$
                    ^.*"GET / HTTP.*" 403.*"(searxng|sonarr|prowlarr|radarr|sabnzbd|jellyseerr|home-assistant|zwavejs|actual|frigate|pihole|fava|unifi|photoprism|stirling-pdf|recipesage)@.*$
    '';
    
    # traefik scanning/probing attempts # add new traefik-scan.conf filter to filter.d
    "fail2ban/filter.d/traefik-scan.conf".text = ''
      [Definition]

      # match common scan patterns returning 404/403/400
      failregex = ^<HOST> - - \[.*\] "(GET|POST|HEAD) /(\.env|\.git|\.aws|wp-admin|wp-login\.php|phpmyadmin|admin|xmlrpc\.php|config\.php|\.htaccess|wp-content|wordpress|\.svn|\.bzr|\.hg|manager|console|actuator|api/v1/pods|solr|jenkins).*HTTP/\d\.\d" (404|403|400) .*$
                  ^<HOST> - - \[.*\] "(GET|POST) .*\.(php|asp|aspx|cgi|jsp).*" (404|403) .*$
                  ^<HOST> - - \[.*\] "GET /robots\.txt HTTP/1\.0" 404 .*$
      
      # ignore legitimate 404s from known services
      ignoreregex = ^.*"GET /.* HTTP/2\.0" 404.*"(nextcloud|jellyfin|home-assistant)@.*$
    '';
    
    # traefik request flooding # add new traefik-flood filter to filter.d
    "fail2ban/filter.d/traefik-flood.conf".text = ''
      [Definition]

      # match any HTTP request (relies on maxretry for rate limiting)
      failregex = ^<HOST> - - \[.*\] "(GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH).*HTTP/\d\.\d" \d+ .*$
      
      # ignore static assets, health checks, and known automated processes
      ignoreregex = ^.*"GET .*\.(css|js|png|jpg|jpeg|gif|ico|woff|woff2|svg|webp|mp4|webm|ttf|eot).*$
                    ^.*"GET /_health.*$
                    ^.*"GET /api/verify.*$
                    ^.*"/ocs/v2\.php/apps/user_status/.*$
                    ^.*"/api/webhook/.*$
    '';
    
  };
  
}