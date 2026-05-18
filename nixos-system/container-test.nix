{ 
  configVars,
  lib,
  ... 
}:

let
  name = "testbox";
  bindDir = "/home/chris/nixos/nixos-configs-private/container-test";
in

{

  networking = {
    nat.enable = true;
    nat.internalInterfaces = [ "ve-${name}" ];
  };

  systemd.services."${name}-preinit" = {
    description = "Ensure ${name} bind-mount directory exists";
    requiredBy = [ "container@${name}.service" ];
    before = [ "container@${name}.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = "mkdir -p ${bindDir}";
  };

  containers.${name} = {
    autoStart = false;
    ephemeral = true;
    privateNetwork = true;
    hostAddress = configVars.containerServices.${name}.hostAddress;
    localAddress = configVars.containerServices.${name}.localAddress;
    bindMounts."/mnt/shared" = {
      hostPath = bindDir;
      isReadOnly = false;
    };
    config = { pkgs, ... }: {
      system.stateVersion = "25.11";
      environment.systemPackages = [ pkgs.curl pkgs.iproute2 ];
      networking.firewall.enable = false;
    };
  };

}