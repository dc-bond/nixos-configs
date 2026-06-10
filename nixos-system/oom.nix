{ ... }:

{

  # OOM protection: kills the worst-offender cgroup when sustained memory pressure builds before the kernel falls back to thrashing
  # systemd-oomd is enabled by default in NixOS 25.11 but does nothing without slice opt-in - the three enable* flags below install ManagedOOMMemoryPressure=kill on
  # the corresponding slices at the NixOS-default 80% pressure limit.
  systemd.oomd = {
    enable = true; # explicit for clarity; default in 25.11
    enableRootSlice = true; # cgroups directly under -.slice
    enableSystemSlice = true; # system services (nix-daemon, oci containers, etc.)
    enableUserSlices = true; # user@.slice and per-user app cgroups - primary win on workstations
  };

}