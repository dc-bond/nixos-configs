{ 
  pkgs, 
  ... 
}: 

{

  services.unbound = {
    enable = true;
    user = "unbound";
    stateDir = "/var/lib/unbound";
    resolveLocalQueries = true; # for pihole running on same machine
    settings = {
      server = {
        verbosity = 4;
        num-threads = 2;
        interface = "0.0.0.0";
        port = "5323";
        do-ip4 = "yes";
        do-udp = "yes";
        do-tcp = "yes";
        do-ip6 = "no";
        prefer-ip6 = "no";
        #root-hints: "/var/lib/unbound/root.hints"
        so-reuseport = "yes";
        harden-glue = "yes";
        harden-dnssec-stripped = "yes";
        harden-algo-downgrade = "yes";
        harden-short-bufsize = "yes";
        harden-large-queries = "yes";
        harden-below-nxdomain = "yes";
        harden-referral-path = "no";
        use-caps-for-id = "no";
        edns-buffer-size = 1232;
        prefetch = "yes";
        so-rcvbuf = "1m";
        log-queries = "no";
        hide-version = "yes";
        hide-identity = "yes";
        qname-minimisation = "yes";
        aggressive-nsec = "yes";
        ratelimit = 1000;
        minimal-responses = "yes";
        rrset-roundrobin = "yes";
        num-queries-per-thread = 4096;
        outgoing-range = 8192;
        msg-cache-size = 260991658;
        rrset-cache-size = 260991658;
        neg-cache-size = "4M";
        serve-expired = "yes";
        unwanted-reply-threshold = "10000";
        val-clean-additional = "yes";
        delay-close = 10000;
        cache-min-ttl = 60;
        cache-max-ttl = 86400;
        do-daemonize "no";
        identity = "DNS";
        #chroot = "/opt/unbound/etc/unbound";
        #directory = "/opt/unbound/etc/unbound";
        auto-trust-anchor-file = "var/lib/unbound/root.key";
        #tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";
        private-address = "10.0.0.0/8";
        private-address = "172.16.0.0/12";
        private-address = "192.168.0.0/16";
        private-address = "169.254.0.0/16"; 
        #private-address = "fd00::/8";
        #private-address = "fe80::/10";
        #private-address = "::ffff:0:0/96";
        #access-control = "127.0.0.1/32 allow
        #access-control = "192.168.0.0/16 allow
        #access-control = "172.16.0.0/12 allow
        #access-control: 172.21.2.0/25 allow # only allow queries from docker backend network (pihole)
        #access-control: 172.21.2.44/32 allow
        #access-control: 10.0.0.0/8 allow
      };
    };
  };

}