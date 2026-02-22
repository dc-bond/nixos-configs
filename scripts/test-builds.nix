{ pkgs, configLib, ... }:

let

  # Dynamically discover all hosts from the hosts directory
  hostsDir = configLib.relativeToRoot "hosts";
  hostEntries = builtins.readDir hostsDir;
  hosts = builtins.filter (name: hostEntries.${name} == "directory") (builtins.attrNames hostEntries);
  hostsString = builtins.concatStringsSep " " hosts;

  testBuildsScript = pkgs.writeShellScriptBin "test-builds" ''
    #!/usr/bin/env bash

    HOSTS=(${hostsString})
    FAILED=()
    FLAKE_DIR="${configLib.relativeToRoot "."}"

    echo ""
    echo "=========================================="
    echo "  Testing builds for all hosts"
    echo "=========================================="
    echo ""

    for host in "''${HOSTS[@]}"; do
      echo -n "Building $host... "
      if nix build "$FLAKE_DIR#nixosConfigurations.$host.config.system.build.toplevel" --no-link 2>/dev/null; then
        echo "✓"
      else
        echo "✗"
        FAILED+=("$host")
      fi
    done

    echo ""
    echo "=========================================="
    if [ ''${#FAILED[@]} -eq 0 ]; then
      echo "  ✓ SUCCESS: All hosts built successfully"
    else
      echo "  ✗ FAILED: ''${#FAILED[@]} host(s) failed to build:"
      for host in "''${FAILED[@]}"; do
        echo "    - $host"
      done
      exit 1
    fi
    echo "=========================================="
    echo ""
  '';

in

{
  environment.systemPackages = [ testBuildsScript ];
}
