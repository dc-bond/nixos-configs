#!/usr/bin/env bash
# NixOS ISO Bootstrap Script
# Usage: curl -sLO https://raw.githubusercontent.com/dc-bond/nixos-configs/main/scripts/bootstrap-iso.sh && bash bootstrap-iso.sh
# Requires: Yubikey with GPG auth subkey (SSH key registered with GitHub)

set -euo pipefail

[[ ! -f /etc/NIXOS ]] && { echo "Must run from NixOS ISO"; exit 1; }

echo "Available hosts: thinkpad, cypress, kauri, aspen, juniper"
read -p "Hostname: " HOSTNAME
[[ -z "$HOSTNAME" ]] && exit 1

# Phase 1: Setup (no PIN required)
echo "Phase 1: Setting up GPG and SSH..."
nix-shell -p gnupg pinentry-curses git pass --run '
set -euo pipefail

echo "Checking for Yubikey..."
gpg --card-status &>/dev/null || { echo "Yubikey not detected"; exit 1; }

echo "Importing GPG key from keyserver..."
gpg --keyserver keyserver.ubuntu.com --recv-keys 012321D46E090E61

echo "Setting GPG key trust level..."
echo -e "trust\n5\ny\nquit" | gpg --command-fd 0 --edit-key chris@dcbond.com

echo "Configuring GPG agent for SSH..."
mkdir -p ~/.gnupg
cat > ~/.gnupg/gpg-agent.conf << EOF
enable-ssh-support
pinentry-program $(which pinentry-curses)
EOF
echo "0220A39C45CB35A72692C72BC35B8E300BDA0690" > ~/.gnupg/sshcontrol

gpgconf --kill gpg-agent
echo "Phase 1 complete."
'

# Phase 2: Manual PIN entry
echo ""
echo "============================================"
echo "Phase 2: Manual step required"
echo "============================================"
echo ""
echo "Run these commands:"
echo ""
echo "  nix-shell -p gnupg pinentry-curses git pass"
echo ""
echo "Then inside nix-shell:"
echo ""
echo "  export GPG_TTY=\$(tty)"
echo "  export SSH_AUTH_SOCK=\$(gpgconf --list-dirs agent-ssh-socket)"
echo "  gpg-connect-agent updatestartuptty /bye"
echo "  ssh -T git@github.com"
echo ""
echo "After successful GitHub auth, run:"
echo ""
echo "  HOSTNAME=$HOSTNAME source ~/bootstrap-phase3.sh"
echo ""

# Write phase 3 script
cat > ~/bootstrap-phase3.sh << 'EOF'
set -euo pipefail

echo "Cloning configs..."
git clone https://github.com/dc-bond/nixos-configs.git ~/nixos-configs 2>/dev/null || (cd ~/nixos-configs && git pull)

echo "Cloning password-store..."
git clone git@github.com:dc-bond/.password-store.git ~/.password-store 2>/dev/null || (cd ~/.password-store && git pull)

echo "Verifying pass access..."
pass show "hosts/${HOSTNAME}/age/private" >/dev/null || { echo "Pass access failed"; exit 1; }

echo ""
echo "WARNING: This will DESTROY all data on the target disk!"
read -p "Type yes to proceed: " CONFIRM
[[ "$CONFIRM" != "yes" ]] && exit 1

echo "Starting bootstrap deployment..."
cd ~/nixos-configs
nix-shell ~/nixos-configs/scripts/bootstrap.nix --run "bootstrap-${HOSTNAME}"

echo "Done! Reboot, login, then run: sudo recoverSnap"
EOF

echo "Phase 3 script written to ~/bootstrap-phase3.sh"
