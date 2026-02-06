#!/usr/bin/env bash
# Usage: curl -sLO https://raw.githubusercontent.com/dc-bond/nixos-configs/main/scripts/bootstrap-iso.sh && bash bootstrap-iso.sh
# Requires: Yubikey with GPG auth subkey configured

set -euo pipefail

[[ ! -f /etc/NIXOS ]] && { echo "Must run from NixOS ISO"; exit 1; }

echo "Available hosts: thinkpad, cypress, kauri, aspen, juniper"
read -p "Hostname: " HOSTNAME
[[ -z "$HOSTNAME" ]] && exit 1

export HOSTNAME

# all GPG setup inside a nix-shell with packages available
nix-shell -p gnupg pinentry-curses git pass --run '
set -euo pipefail

# set up environment variables
export GPG_TTY=$(tty)
export HOSTNAME="'"$HOSTNAME"'"

echo "Setting up GPG environment..."
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# configure GPG agent with SSH support
cat > ~/.gnupg/gpg-agent.conf <<EOF
enable-ssh-support
pinentry-program $(command -v pinentry-curses)
default-cache-ttl 3600
max-cache-ttl 7200
EOF

# add the GPG auth subkey to sshcontrol (from bootstrap.nix line 29)
echo "0220A39C45CB35A72692C72BC35B8E300BDA0690" > ~/.gnupg/sshcontrol

echo "Importing GPG key..."
gpg --keyserver keyserver.ubuntu.com --recv-keys 012321D46E090E61
echo -e "trust\n5\ny\nquit" | gpg --command-fd 0 --edit-key chris@dcbond.com

# kill and restart agent to pick up config
gpgconf --kill gpg-agent
gpg-connect-agent /bye

# update GPG agent with current TTY
gpg-connect-agent updatestartuptty /bye

# verify yubikey
echo "Checking for Yubikey..."
gpg --card-status || { echo "Yubikey not detected"; exit 1; }

# export SSH_AUTH_SOCK for GPG SSH support
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# test SSH auth (this will trigger pinentry)
echo "Testing SSH authentication..."
ssh-add -L || { echo "No SSH keys from GPG agent"; exit 1; }
echo "SSH key loaded from Yubikey successfully"

echo "Cloning repos via SSH..."
git clone git@github.com:dc-bond/nixos-configs.git ~/nixos-configs
git clone git@github.com:dc-bond/.password-store.git ~/.password-store

echo "Verifying pass access..."
pass show "hosts/$HOSTNAME/age/private" >/dev/null || { echo "Pass access failed"; exit 1; }

echo ""
echo "Checking system resources..."

# check available RAM
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk "{print \$2}")
TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
AVAILABLE_RAM_KB=$(grep MemAvailable /proc/meminfo | awk "{print \$2}")
AVAILABLE_RAM_GB=$((AVAILABLE_RAM_KB / 1024 / 1024))

echo "Total RAM: ${TOTAL_RAM_GB} GB"
echo "Available RAM: ${AVAILABLE_RAM_GB} GB"

# calculate safe tmpfs size (leave 4GB for ISO + overhead)
MIN_RAM_GB=16
REQUIRED_TMPFS_GB=12
SAFE_TMPFS_GB=$((AVAILABLE_RAM_GB - 4))

if [ "$TOTAL_RAM_GB" -lt "$MIN_RAM_GB" ]; then
    echo ""
    echo "WARNING: System has only ${TOTAL_RAM_GB} GB RAM"
    echo "Recommended minimum: ${MIN_RAM_GB} GB for reliable builds"
    echo "Build may fail due to insufficient tmpfs space"
    read -p "Continue anyway? (yes/no): " CONTINUE
    [[ "$CONTINUE" != "yes" ]] && exit 1
    TMPFS_SIZE_GB=$SAFE_TMPFS_GB
else
    TMPFS_SIZE_GB=$REQUIRED_TMPFS_GB
fi

# expand tmpfs for build
echo ""
echo "Expanding tmpfs to ${TMPFS_SIZE_GB}G for NixOS build..."
sudo mount -o remount,size=${TMPFS_SIZE_GB}G /nix/.rw-store || {
    echo "Failed to expand tmpfs - build will likely fail"
    read -p "Continue anyway? (yes/no): " CONTINUE
    [[ "$CONTINUE" != "yes" ]] && exit 1
}

# show available space
TMPFS_AVAIL=$(df -h /nix/.rw-store | tail -1 | awk "{print \$4}")
echo "Available tmpfs space: $TMPFS_AVAIL"
echo ""

echo "Starting deployment..."
cd ~/nixos-configs
nix-shell ~/nixos-configs/scripts/bootstrap.nix --run "bootstrap-$HOSTNAME"
'

echo "Done! Reboot, login, then run: sudo recoverSnap"