#!/usr/bin/env bash
# NixOS ISO Bootstrap Script
# Usage: curl -sLO https://raw.githubusercontent.com/dc-bond/nixos-configs/main/scripts/bootstrap-iso.sh && bash bootstrap-iso.sh
# Requires: Yubikey, GitHub token with repo access to dc-bond/.password-store

set -euo pipefail

[[ ! -f /etc/NIXOS ]] && { echo "Must run from NixOS ISO"; exit 1; }

echo "Available hosts: thinkpad, cypress, kauri, aspen, juniper"
read -p "Hostname: " HOSTNAME
[[ -z "$HOSTNAME" ]] && exit 1

read -sp "GitHub token: " GH_TOKEN
echo ""

export HOSTNAME GH_TOKEN

nix-shell -p gnupg pinentry-curses git pass --run '
set -euo pipefail

echo "Checking for Yubikey..."
gpg --card-status &>/dev/null || { echo "Yubikey not detected"; exit 1; }

echo "Importing GPG key..."
gpg --keyserver keyserver.ubuntu.com --recv-keys 012321D46E090E61
echo -e "trust\n5\ny\nquit" | gpg --command-fd 0 --edit-key chris@dcbond.com

echo "Configuring GPG agent..."
mkdir -p ~/.gnupg
echo "pinentry-program $(which pinentry-curses)" > ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye

echo "Cloning repos..."
git clone https://github.com/dc-bond/nixos-configs.git ~/nixos-configs
git clone "https://${GH_TOKEN}@github.com/dc-bond/.password-store.git" ~/.password-store

echo "Verifying pass access..."
pass show "hosts/${HOSTNAME}/age/private" >/dev/null || { echo "Pass access failed"; exit 1; }

echo ""
echo "WARNING: This will DESTROY all data on the target disk!"
read -p "Type yes to proceed: " CONFIRM
[[ "$CONFIRM" != "yes" ]] && exit 1

echo "Starting deployment..."
cd ~/nixos-configs
nix-shell ~/nixos-configs/scripts/bootstrap.nix --run "bootstrap-${HOSTNAME}"
'

echo "Done! Reboot, login, then run: sudo recoverSnap"
