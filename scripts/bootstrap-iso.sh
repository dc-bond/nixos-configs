#!/usr/bin/env bash
# NixOS ISO Bootstrap Script
# Usage: curl -sLO https://raw.githubusercontent.com/dc-bond/nixos-configs/main/scripts/bootstrap-iso.sh && bash bootstrap-iso.sh
# Requires: Yubikey with GPG auth subkey configured

set -euo pipefail

[[ ! -f /etc/NIXOS ]] && { echo "Must run from NixOS ISO"; exit 1; }

echo "Available hosts: thinkpad, cypress, kauri, aspen, juniper"
read -p "Hostname: " HOSTNAME
[[ -z "$HOSTNAME" ]] && exit 1

export HOSTNAME
export GPG_TTY=$(tty)

# Install required packages first
echo "Installing required packages..."
nix-shell -p gnupg pinentry-curses git pass --run 'true'

# Setup GPG agent BEFORE entering the main shell
echo "Setting up GPG environment..."
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# Configure GPG agent with SSH support
cat > ~/.gnupg/gpg-agent.conf <<EOF
enable-ssh-support
pinentry-program $(command -v pinentry-curses)
default-cache-ttl 3600
max-cache-ttl 7200
EOF

# Add the GPG auth subkey to sshcontrol (from bootstrap.nix line 29)
echo "0220A39C45CB35A72692C72BC35B8E300BDA0690" > ~/.gnupg/sshcontrol

echo "Importing GPG key..."
nix-shell -p gnupg --run '
gpg --keyserver keyserver.ubuntu.com --recv-keys 012321D46E090E61
echo -e "trust\n5\ny\nquit" | gpg --command-fd 0 --edit-key chris@dcbond.com
'

# Kill and restart agent to pick up config
gpgconf --kill gpg-agent
gpg-connect-agent /bye

# Verify Yubikey
echo "Checking for Yubikey..."
gpg --card-status || { echo "Yubikey not detected"; exit 1; }

# Export SSH_AUTH_SOCK for GPG SSH support
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# Test SSH auth (this will trigger pinentry)
echo "Testing SSH authentication..."
ssh-add -L || { echo "No SSH keys from GPG agent"; exit 1; }
echo "SSH key loaded from Yubikey successfully"

# Now enter the main shell with environment already configured
nix-shell -p git pass --run '
set -euo pipefail

echo "Cloning repos via SSH..."
git clone git@github.com:dc-bond/nixos-configs.git ~/nixos-configs
git clone git@github.com:dc-bond/.password-store.git ~/.password-store

echo "Verifying pass access..."
pass show "hosts/$HOSTNAME/age/private" >/dev/null || { echo "Pass access failed"; exit 1; }

echo ""
echo "WARNING: This will DESTROY all data on the target disk!"
read -p "Type yes to proceed: " CONFIRM
[[ "$CONFIRM" != "yes" ]] && exit 1

echo "Starting deployment..."
cd ~/nixos-configs
nix-shell ~/nixos-configs/scripts/bootstrap.nix --run "bootstrap-$HOSTNAME"
'

echo "Done! Reboot, login, then run: sudo recoverSnap"
