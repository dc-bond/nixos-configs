{
  pkgs,
  lib,
  config,
  configVars,
  ...
}:

let

  hostname = config.networking.hostName;
  sshPort = configVars.hosts.${hostname}.networking.sshPort;

in

{

  sops.secrets."${hostname}SshKey" = {
    mode = "0600";
    owner = "root";
    group = "root";
    path = "/etc/ssh/ssh_host_ed25519_key";
  };

  services.openssh = lib.mkMerge [
    # host keys apply to all hosts (needed for tailscale ssh)
    {
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    }
    # ssh daemon only enabled for hosts with sshPort set in configVars
    (lib.mkIf (sshPort != null) {
      enable = true;
      ports = [ sshPort ];
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
        LogLevel = "VERBOSE";
      };
    })
  ];

  programs.ssh.knownHosts =
    # auto-generate for all hosts from configVars
    lib.mapAttrs (hostname: hostConfig:
      let
        net = hostConfig.networking;
      in {
        hostNames =
          # always include tailscale IP
          [ net.tailscaleIp ]
          # include regular ipv4 if sshPort is null (tailscale-only hosts)
          ++ lib.optional (net.sshPort == null && net.ipv4 != null) net.ipv4
          # include bracketed ipv4:port if sshPort is set
          ++ lib.optional (net.sshPort != null && net.ipv4 != null)
               "[${net.ipv4}]:${toString net.sshPort}"
          # special case: aspen gets dns alias for public access
          ++ lib.optional (hostname == "aspen") "ssh.${configVars.domain1}";
        publicKey = net.sshPublicKey;
      }
    ) configVars.hosts
    # add non-host entries
    // {
      "github" = {
        hostNames = [ "github.com" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      };
    };

}