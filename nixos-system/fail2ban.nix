{ 
  pkgs, 
  config, 
  lib, 
  configVars,
  ... 
}:

{
  services.fail2ban = {
    enable = true;
    
    # Global settings
    maxretry = 3;
    bantime = "1h";
    findtime = "10m";
    
    # Use systemd backend for journal integration
    extraPackages = [ pkgs.systemd ];
    
    jails = {
      
      # Monitor authentication failures through Traefik
      traefik-auth = {
        enabled = true;
        filter = "traefik-auth";
        logpath = "systemd-journal";
        backend = "systemd";
        journalmatch = "_SYSTEMD_UNIT=traefik.service";
        maxretry = 5;        # Allow more retries for legitimate users
        bantime = "2h";      # Longer ban for persistent attackers
        findtime = "10m";    # Look for patterns over 10 minutes
        action = "iptables-allports[name=traefik-auth]";
      };
      
      # Monitor scanning/probing attempts through Traefik
      traefik-scan = {
        enabled = true;
        filter = "traefik-scan";
        logpath = "systemd-journal";
        backend = "systemd";
        journalmatch = "_SYSTEMD_UNIT=traefik.service";
        maxretry = 2;        # Very low tolerance for scanning
        bantime = "4h";      # Long ban for reconnaissance attempts
        findtime = "5m";     # Quick detection window
        action = "iptables-allports[name=traefik-scan]";
      };
      
      # Monitor excessive request rates through Traefik
      traefik-flood = {
        enabled = true;
        filter = "traefik-flood";
        logpath = "systemd-journal";
        backend = "systemd";
        journalmatch = "_SYSTEMD_UNIT=traefik.service";
        maxretry = 100;      # Allow reasonable request volume
        bantime = "30m";     # Shorter ban for potential false positives
        findtime = "2m";     # Short window to detect rapid requests
        action = "iptables-allports[name=traefik-flood]";
      };
      
      # Nextcloud authentication failures
      nextcloud-auth = {
        enabled = true;
        filter = "nextcloud-auth";
        logpath = "systemd-journal";
        backend = "systemd";
        journalmatch = "_SYSTEMD_UNIT=phpfpm-nextcloud.service";
        maxretry = 3;
        bantime = "1h";
        findtime = "10m";
        action = "iptables-allports[name=nextcloud-auth]";
      };
      
      # Matrix Synapse protection
      matrix-auth = {
        enabled = true;
        filter = "matrix-auth";
        logpath = "systemd-journal";
        backend = "systemd";
        journalmatch = "_SYSTEMD_UNIT=matrix-synapse.service";
        maxretry = 5;        # Matrix clients can retry frequently
        bantime = "30m";     # Shorter ban for legitimate client retries
        findtime = "15m";
        action = "iptables-allports[name=matrix-auth]";
      };
      
      # SSH brute force protection (even though key-only)
      sshd = {
        enabled = true;
        port = "ssh,${toString config.hostSpecificConfigs.sshdPort}";
        filter = "sshd";
        maxretry = 3;
        bantime = "10m";
        findtime = "5m";
        action = "iptables-allports[name=sshd]";
      };
      
    };
  };

  # Custom filter definitions
  environment.etc = {
    
    # Traefik authentication failures
    "fail2ban/filter.d/traefik-auth.conf".text = ''
      # Traefik Authentication Failures
      [Definition]
      
      # Match 401 (Unauthorized) and 403 (Forbidden) responses
      failregex = ^.*"(GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH)" \S+ HTTP/\d+\.\d+" (401|403) .*"<HOST>".*$
      
      # Ignore legitimate Authelia redirects and health checks
      ignoreregex = ^.*"/api/verify.*$
                   ^.*"/_health.*$
    '';
    
    # Traefik scanning/probing attempts  
    "fail2ban/filter.d/traefik-scan.conf".text = ''
      # Traefik Scanning/Probing Detection
      [Definition]
      
      # Match common scan patterns for non-existent endpoints
      failregex = ^.*"(GET|POST)" "/(\.env|\.git|wp-admin|wp-login|phpmyadmin|admin|xmlrpc|config\.php|\.htaccess)" HTTP/\d+\.\d+" (404|403) .*"<HOST>".*$
                 ^.*"(GET|POST)" "/\.(svn|bzr|hg)/" HTTP/\d+\.\d+" (404|403) .*"<HOST>".*$
                 ^.*"(GET|POST)" "/(test|debug|api/v\d+/test)" HTTP/\d+\.\d+" (404|403) .*"<HOST>".*$
      
      ignoreregex =
    '';
    
    # Traefik request flooding
    "fail2ban/filter.d/traefik-flood.conf".text = ''
      # Traefik Request Flooding Detection
      [Definition]
      
      # Match any HTTP request (will rely on maxretry for rate limiting)
      failregex = ^.*"(GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH)" \S+ HTTP/\d+\.\d+" \d+ .*"<HOST>".*$
      
      # Ignore static assets and health checks
      ignoreregex = ^.*"\.(css|js|png|jpg|jpeg|gif|ico|woff|woff2|svg)" .*$
                   ^.*"/_health.*$
                   ^.*"/api/verify.*$
    '';
    
    # Nextcloud authentication failures
    "fail2ban/filter.d/nextcloud-auth.conf".text = ''
      # Nextcloud Authentication Failures
      [Definition]
      
      # Match Nextcloud login failures from systemd journal
      failregex = ^\[.*\] WARNING -- .*Login failed: '.*' \(Remote IP: '<HOST>'\).*$
                 ^\[.*\] WARNING -- .*Bruteforce attempt from "<HOST>".*$
                 ^\[.*\] ERROR -- .*Login attempt blocked for <HOST>.*$
      
      ignoreregex =
    '';
    
    # Matrix Synapse authentication failures
    "fail2ban/filter.d/matrix-auth.conf".text = ''
      # Matrix Synapse Authentication Failures  
      [Definition]
      
      # Match Matrix authentication failures
      failregex = ^.*- synapse\.access\.http\.\d+ - \d+ - \{.*\} "POST .*/_matrix/client/.*/login HTTP.*" "401" .* "<HOST>" .*$
                 ^.*- synapse\.access\.http\.\d+ - \d+ - \{.*\} "POST .*/_matrix/client/.*/register HTTP.*" "401" .* "<HOST>" .*$
                 ^.*Failed to authenticate request.*client_ip='<HOST>'.*$
      
      ignoreregex =
    '';
    
  };

  # Network configuration for fail2ban
  networking.firewall = {
    # Allow fail2ban to manage iptables rules
    extraCommands = ''
      # Create fail2ban chains if they don't exist
      iptables -N f2b-traefik-auth 2>/dev/null || true
      iptables -N f2b-traefik-scan 2>/dev/null || true  
      iptables -N f2b-traefik-flood 2>/dev/null || true
      iptables -N f2b-nextcloud-auth 2>/dev/null || true
      iptables -N f2b-matrix-auth 2>/dev/null || true
      iptables -N f2b-sshd 2>/dev/null || true
      
      # Insert chains into INPUT if not already present
      iptables -C INPUT -p tcp --dport 80 -j f2b-traefik-auth 2>/dev/null || iptables -I INPUT -p tcp --dport 80 -j f2b-traefik-auth
      iptables -C INPUT -p tcp --dport 443 -j f2b-traefik-auth 2>/dev/null || iptables -I INPUT -p tcp --dport 443 -j f2b-traefik-auth
      iptables -C INPUT -p tcp --dport 443 -j f2b-traefik-scan 2>/dev/null || iptables -I INPUT -p tcp --dport 443 -j f2b-traefik-scan
      iptables -C INPUT -p tcp --dport 443 -j f2b-traefik-flood 2>/dev/null || iptables -I INPUT -p tcp --dport 443 -j f2b-traefik-flood
      iptables -C INPUT -p tcp --dport ${toString config.hostSpecificConfigs.sshdPort} -j f2b-sshd 2>/dev/null || iptables -I INPUT -p tcp --dport ${toString config.hostSpecificConfigs.sshdPort} -j f2b-sshd
    '';
    
    extraStopCommands = ''
      # Clean up fail2ban chains on firewall stop
      iptables -D INPUT -p tcp --dport 80 -j f2b-traefik-auth 2>/dev/null || true
      iptables -D INPUT -p tcp --dport 443 -j f2b-traefik-auth 2>/dev/null || true
      iptables -D INPUT -p tcp --dport 443 -j f2b-traefik-scan 2>/dev/null || true
      iptables -D INPUT -p tcp --dport 443 -j f2b-traefik-flood 2>/dev/null || true
      iptables -D INPUT -p tcp --dport ${toString config.hostSpecificConfigs.sshdPort} -j f2b-sshd 2>/dev/null || true
      
      iptables -F f2b-traefik-auth 2>/dev/null || true
      iptables -F f2b-traefik-scan 2>/dev/null || true
      iptables -F f2b-traefik-flood 2>/dev/null || true
      iptables -F f2b-nextcloud-auth 2>/dev/null || true
      iptables -F f2b-matrix-auth 2>/dev/null || true  
      iptables -F f2b-sshd 2>/dev/null || true
      
      iptables -X f2b-traefik-auth 2>/dev/null || true
      iptables -X f2b-traefik-scan 2>/dev/null || true
      iptables -X f2b-traefik-flood 2>/dev/null || true
      iptables -X f2b-nextcloud-auth 2>/dev/null || true
      iptables -X f2b-matrix-auth 2>/dev/null || true
      iptables -X f2b-sshd 2>/dev/null || true
    '';
  };

  systemd.services.fail2ban = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

}