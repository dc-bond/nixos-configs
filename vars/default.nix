{ 
  inputs, 
  lib 
}:

{

  hosts = {

    aspen = {
      system = "x86_64-linux";
      nixpkgsVersion = "25.05";
      users = [ "chris" ];
      bootLoader = "systemd-boot";
      isMonitoringServer = true;
      windowManager = null;
      networking = {
        sshPort = 28766;
        useResolved = false; # runs pihole
        ethernetInterface = "enp4s0";
        wifiInterface = null;
        dockInterface = null;
        ipv4 = "192.168.1.2";
        tailscaleIp = "100.68.250.108";
        tailscale = {
          role = "exit-node";
          advertiseRoutes = [ 
            "192.168.1.0/24" 
            "192.168.4.0/27" 
          ];
          enableNAT = true;
          defaultExitNode = null;
        };
      };
      hardware = {
        diskEncryption = false;
        enableSmartMonitoring = true;
        storageDrives = {
          data = {
            mountPoint = "/storage/WD-WCC7K4RU947F";
            uuid = "2dbedc67-9a6b-477f-a3b4-75116994d1cb";
            fsType = "ext4";
          };
        };
        hasBattery = false;
        hasBluetooth = false;
        hasBacklight = false;
      };
    };

    thinkpad = {
      system = "x86_64-linux";
      nixpkgsVersion = "25.05";
      users = [ "chris" ];
      bootLoader = "systemd-boot";
      isMonitoringServer = false;
      windowManager = "hyprland";
      networking = {
        sshPort = null; # only use tailscale ssh
        useResolved = true;
        ethernetInterface = "enp0s31f6";
        wifiInterface = "wlan0";
        dockInterface = "enp0s20f0u2u1u2";
        ipv4 = "192.168.1.62";
        tailscaleIp = "100.66.143.66";
        tailscale = {
          role = "client";
          #advertiseRoutes = [ 
          #];
          enableNAT = false;
          defaultExitNode = "aspen";
        };
      };
      hardware = {
        diskEncryption = true;
        enableSmartMonitoring = true;
        storageDrives = {};
        hasBattery = true;
        hasBluetooth = true;
        hasBacklight = true;
      };
    };
    
    cypress = {
      system = "x86_64-linux";
      nixpkgsVersion = "25.05";
      users = [ "chris" ];
      bootLoader = "systemd-boot";
      isMonitoringServer = false;
      windowManager = "hyprland";
      networking = {
        sshPort = null; # only use tailscale ssh
        useResolved = true;
        ethernetInterface = "enp1s0";
        wifiInterface = null;
        dockInterface = null;
        ipv4 = "192.168.1.89";
        tailscaleIp = "100.84.248.69";
        tailscale = {
          role = "client";
          #advertiseRoutes = [ 
          #];
          enableNAT = false;
          defaultExitNode = "aspen";
        };
      };
      hardware = {
        diskEncryption = false;
        enableSmartMonitoring = true;
        storageDrives = {
          data = {
            mountPoint = "/storage/WD-WX21DC86RU3P";
            uuid = "f3fb53cc-52fa-48e3-8cac-b69d85a8aff1";
            fsType = "ext4";
          };
        };
        hasBattery = false;
        hasBluetooth = true;
        hasBacklight = false;
      };
    };

    juniper = {
      system = "x86_64-linux";
      nixpkgsVersion = "25.05";
      users = [ "chris" ];
      bootLoader = "grub";
      isMonitoringServer = false;
      windowManager = null;
      networking = {
        sshPort = 28764;
        useResolved = true;
        ethernetInterface = "enp1s0";
        wifiInterface = null;
        dockInterface = null;
        ipv4 = "178.156.133.218";
        tailscaleIp = "100.70.221.14";
        tailscale = {
          role = "exit-node";
          #advertiseRoutes = [ 
          #];
          enableNAT = false;
          defaultExitNode = null;
        };
      };
      hardware = {
        diskEncryption = false;
        enableSmartMonitoring = false;
        storageDrives = {};
        hasBattery = false;
        hasBluetooth = false;
        hasBacklight = false;
      };
    };
    
    alder = {
      system = "x86_64-linux";
      nixpkgsVersion = "25.05";
      users = [ 
        "eric" 
      ];
      bootLoader = "systemd-boot";
      isMonitoringServer = false;
      windowManager = "labwc";
      networking = {
        sshPort = null;
        useResolved = true;
        ethernetInterface = null;
        wifiInterface = "wlan0";
        dockInterface = null;
        ipv4 = "192.168.4.15";
        tailscaleIp = "100.68.185.99";
        tailscale = {
          role = "client";
          #advertiseRoutes = [ 
          #];
          enableNAT = false;
          defaultExitNode = "aspen";
        };
      };
      hardware = {
        diskEncryption = true;
        enableSmartMonitoring = true;
        storageDrives = {};
        hasBattery = false;
        hasBluetooth = true;
        hasBacklight = true;
      };
    };

  };
  
  devices = {
    chrisIphone15 = {
      tailscaleIp = "100.123.43.13";
    };
    daniellePixel7a = {
      tailscaleIp = "100.91.224.34";
    };
    sydneyIphone6 = {
      tailscaleIp = "100.122.145.11";
    };
    rokuGym = {
      ipv4 = "192.168.4.9";
    };
    rokuLivingroom = {
      ipv4 = "192.168.4.10";
    };
    unifiUsg = {
      ipv4 = "192.168.1.1";
    };
    unifiSwitch8 = {
      ipv4 = "192.168.1.199";
    };
    unifiSwitch8Lite = {
      ipv4 = "192.168.1.151";
    };
    unifiUapGarage = {
      ipv4 = "192.168.1.191";
    };
    unifiUapLivingRoom = {
      ipv4 = "192.168.1.6";
    };
    frontCamera = {
      ipv4 = "192.168.1.132";
    };
    garageCamera = {
      ipv4 = "192.168.1.131";
    };
    gymCamera = {
      ipv4 = "192.168.1.30";
    };
  };

  domain1 = "dcbond.com";
  domain1Short = "dcbond";
  domain2 = "opticon.dev";
  domain2Short = "opticon";
  domain3 = "professorbond.com";
  domain3Short = "professorbond";

  containerServices = {

    pihole = {
      subnet = "172.21.1.0/25";
      containers = {
        pihole = { ipv4 = "172.21.1.2"; };
        unbound = { ipv4 = "172.21.1.3"; };
      };
    };
    
    pihole-test = {
      subnet = "172.21.2.0/25";
      containers = {
        pihole-test = { ipv4 = "172.21.2.2"; };
        unbound-test = { ipv4 = "172.21.2.3"; };
      };
    };
    
    unifi = {
      subnet = "172.21.3.0/25";
      containers = {
        controller = { ipv4 = "172.21.3.2"; };
        mongodb = { ipv4 = "172.21.3.3"; };
      };
    };
    
    zwavejs = {
      subnet = "172.21.4.0/25";
      containers = {
        zwavejs = { ipv4 = "172.21.4.2"; };
      };
    };
    
    actual = {
      subnet = "172.21.5.0/25";
      containers = {
        actual = { ipv4 = "172.21.5.2"; };
      };
    };
    
    fava = {
      subnet = "172.21.6.0/25";
      containers = {
        fava = { ipv4 = "172.21.6.2"; };
      };
    };
    
    recipesage = {
      subnet = "172.21.7.0/25";
      containers = {
        proxy = { ipv4 = "172.21.7.2"; };
        static = { ipv4 = "172.21.7.3"; };
        api = { ipv4 = "172.21.7.4"; };
        typesense = { ipv4 = "172.21.7.5"; };
        pushpin = { ipv4 = "172.21.7.6"; };
        postgres = { ipv4 = "172.21.7.7"; };
        browserless = { ipv4 = "172.21.7.8"; };
        ingredient-instruction-classifier = { ipv4 = "172.21.7.9"; };
      };
    };
    
    #null = {
    #  subnet = "172.21.8.0/25";
    #  containers = {
    #    null = { ipv4 = "172.21.8.2"; };
    #  };
    #};
    
    #null = {
    #  subnet = "172.21.9.0/25";
    #  containers = {
    #    null = { ipv4 = "172.21.9.2"; };
    #  };
    #};
    
    searxng = {
      subnet = "172.21.10.0/25";
      containers = {
        searxng = { ipv4 = "172.21.10.2"; };
      };
    };
    
    traefikCerts = {
      subnet = "172.21.11.0/25";
      containers = {
        certs = { ipv4 = "172.21.11.2"; };
      };
    };
    
    media-server = {
      subnet = "172.21.12.0/25";
      containers = {
        media-server-vpn = { ipv4 = "172.21.12.2"; };
      };
    };
    
    frigate = {
      subnet = "172.21.13.0/25";
      containers = {
        frigate = { ipv4 = "172.21.13.2"; };
      };
    };
    
    #null = {
    #  subnet = "172.21.14.0/25";
    #  containers = {
    #    null = { ipv4 = "172.21.14.2"; };
    #  };
    #};
    
    #null = {
    #  subnet = "172.21.15.0/25";
    #  containers = {
    #    null = { ipv4 = "172.21.15.2"; };
    #  };
    #};
    
    librechat = {
      subnet = "172.21.16.0/25";
      containers = {
        api = { ipv4 = "172.21.16.2"; };
        mongodb = { ipv4 = "172.21.16.3"; };
        meilisearch = { ipv4 = "172.21.16.4"; };
        vectordb = { ipv4 = "172.21.16.5"; };
        rag_api = { ipv4 = "172.21.16.6"; };
      };
    };
    
    n8n = {
      subnet = "172.21.17.0/25";
      containers = {
        n8n = { ipv4 = "172.21.17.2"; };
        "n8n-postgres" = { ipv4 = "172.21.17.3"; };
      };
    };
    
    finplanner = {
      subnet = "172.21.18.0/25";
      containers = {
        finplanner = { ipv4 = "172.21.18.2"; };
      };
    };
    
    chris-workouts = {
      subnet = "172.21.19.0/25";
      containers = {
        chris-workouts = { ipv4 = "172.21.19.2"; };
      };
    };
    
    danielle-workouts = {
      subnet = "172.21.20.0/25";
      containers = {
        danielle-workouts = { ipv4 = "172.21.20.2"; };
      };
    };

  };

  users = {

    chris = {
      uid = 1000;
      fullName = "Chris Bond";
      email = "chris@dcbond.com";
      shell = "zsh";
      sudoNoPasswd = true;
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDesi3Wba5w6/ZV0kgO4hCcG+n7cDwMuSGca/pCqW4zNlCA95Yd9enkQIAtJfUuXbMjZI7DPezcCptDMySUIBU+Lc3WKScJUsaAUjQCSAEv8E1mq6/qg2p2/0GSyl9NONE1iMlASiq8M/q04CL9E7SD6XJCKtqdAOP4mPi5+xzUJ85tvBlyeF8fTsDGQeUSkMm/N31zuymx9lIgf7KQ7bbV0L5Z5R7cSoGs2NrZDnhMpqFYVCh4LA/hhHg7ed8DE96xSJ6GUnulGVa1C8kCVa/fbU1tNBXfOBCooh7yL1MDGAyseAQC4g2ThwWR9Fpyy23Mn9hrr6tuoZ9lwji5RpthuHOYFey82kaDa50yop2BWwN3yXDZjnWJB6Eo8VrGql9o/WytjRh7YvMCC30jAEHEH8IVYGIT14zO9bC5CCCoP6wonkGjhlhdYJFKPQPKZ6X+bESXaC6+3FXY7CsiI/mWxjc5fdJVQRXZDrZaPwhvt292aSZCTY0sDcFwn8HeOO8= openpgp:0xE5DCB627"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEN0XxVGmBh0TYfJ0wLhWRJuy4c/Rgtjyu66R/cvhNYo root@cypress" # ssh key for remote builds
      ];
      gpgKeyFingerprint = "DB9ADBBE6FBD1F0E694AF25D012321D46E090E61";
      gpgPubKeyBlock = ''
        -----BEGIN PGP PUBLIC KEY BLOCK-----

        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
        Vf5rGF/EvFNTfZ0gBRrwppg=
        =0jOo
        
        -----END PGP PUBLIC KEY BLOCK-----
      '';
    };

    eric = {
      uid = 1001;
      fullName = null;
      email = null;
      shell = "zsh";
      sudoNoPasswd = true;
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDesi3Wba5w6/ZV0kgO4hCcG+n7cDwMuSGca/pCqW4zNlCA95Yd9enkQIAtJfUuXbMjZI7DPezcCptDMySUIBU+Lc3WKScJUsaAUjQCSAEv8E1mq6/qg2p2/0GSyl9NONE1iMlASiq8M/q04CL9E7SD6XJCKtqdAOP4mPi5+xzUJ85tvBlyeF8fTsDGQeUSkMm/N31zuymx9lIgf7KQ7bbV0L5Z5R7cSoGs2NrZDnhMpqFYVCh4LA/hhHg7ed8DE96xSJ6GUnulGVa1C8kCVa/fbU1tNBXfOBCooh7yL1MDGAyseAQC4g2ThwWR9Fpyy23Mn9hrr6tuoZ9lwji5RpthuHOYFey82kaDa50yop2BWwN3yXDZjnWJB6Eo8VrGql9o/WytjRh7YvMCC30jAEHEH8IVYGIT14zO9bC5CCCoP6wonkGjhlhdYJFKPQPKZ6X+bESXaC6+3FXY7CsiI/mWxjc5fdJVQRXZDrZaPwhvt292aSZCTY0sDcFwn8HeOO8= openpgp:0xE5DCB627"
      ];
      gpgKeyFingerprint = null;
      gpgPubKeyBlock = null; 
    };

  };

  mailservers = {
    namecheap = {
      smtpHost = "mail.privateemail.com";
      smtpPort = 587; # STARTTLS
      imapPort = 993;
    };
  };
  
}