{ 
  config,
  lib,
  configVars,
  ... 
}:

let
  hostname = config.networking.hostName;
  isBuilder = configVars.hosts.${hostname}.isBuilder or false;
  buildFor = configVars.hosts.${hostname}.buildFor or [];
  
  # Generate build machines list from buildFor
  buildMachines = map (targetHost: 
    let
      targetConfig = configVars.hosts.${targetHost};
      targetPrimaryUser = builtins.head targetConfig.users; # Use first user
    in {
      hostName = "${targetHost}-tailscale"; # Tries tailscale first
      systems = [ targetConfig.system ];
      protocol = "ssh-ng";
      maxJobs = targetConfig.builderMaxJobs or 4;
      speedFactor = targetConfig.builderSpeedFactor or 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      sshUser = targetPrimaryUser;
    }
  ) buildFor;
  
in

{
  # Configuration for machines that USE remote builders
  config = lib.mkIf (buildFor != []) {
    
    # Deploy the private SSH key
    sops.secrets.builderSshKey = {
      mode = "0600";
      owner = "root";
      group = "root";
      path = "/root/.ssh/id_builder";
    };
    
    # Configure distributed builds
    nix = {
      distributedBuilds = true;
      inherit buildMachines;
      
      extraOptions = ''
        builders-use-substitutes = true
      '';
      
      settings.connect-timeout = 5;
    };
    
    # Configure SSH for root
    programs.ssh.extraConfig = lib.concatMapStringsSep "\n" (target: ''
      Host ${target}-tailscale ${target}
        User ${builtins.head configVars.hosts.${target}.users}
        IdentityFile /root/.ssh/id_builder
        IdentitiesOnly yes
        ControlMaster auto
        ControlPath /tmp/ssh-%r@%h:%p
        ControlPersist 600
    '') buildFor;
    
  };
  
  # Configuration for machines that ARE builders
  # Add the builder public key to the primary user's authorized_keys
  users.users = lib.mkIf isBuilder (
    let
      primaryUser = builtins.head config.networking.hostName;
    in {
      ${primaryUser}.openssh.authorizedKeys.keys = [ 
        configVars.systemSshKeys.builderKey 
      ];
    }
  );
  
  # Mark user as trusted on builder machines
  nix.settings.trusted-users = lib.mkIf isBuilder 
    (configVars.hosts.${hostname}.users);
}