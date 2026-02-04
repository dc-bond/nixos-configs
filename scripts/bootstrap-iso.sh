#!/usr/bin/env bash
# NixOS ISO Bootstrap Script
# Usage: curl -sL https://raw.githubusercontent.com/dc-bond/nixos-configs/main/scripts/bootstrap-iso.sh | bash
# Requires: Yubikey with GPG auth subkey (SSH key registered with GitHub)

set -euo pipefail

[[ ! -f /etc/NIXOS ]] && { echo "Must run from NixOS ISO"; exit 1; }

echo "Available hosts: thinkpad, cypress, kauri, aspen, juniper"
read -p "Hostname: " HOSTNAME
[[ -z "$HOSTNAME" ]] && exit 1

export HOSTNAME

nix-shell -p gnupg pinentry-curses git pass --run '
set -euo pipefail

# setup GPG with yubikey
gpg --card-status &>/dev/null || { echo "Yubikey not detected"; exit 1; }
gpg --keyserver keyserver.ubuntu.com --recv-keys 012321D46E090E61
echo -e "trust\n5\ny\nquit" | gpg --command-fd 0 --edit-key chris@dcbond.com

# configure GPG agent for SSH
mkdir -p ~/.gnupg
cat > ~/.gnupg/gpg-agent.conf << EOF
enable-ssh-support
pinentry-program $(which pinentry-curses)
EOF
echo "0220A39C45CB35A72692C72BC35B8E300BDA0690" > ~/.gnupg/sshcontrol
gpgconf --kill gpg-agent
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpg-connect-agent updatestartuptty /bye >/dev/null

# test SSH to github
echo "Testing SSH to GitHub (touch Yubikey when it blinks)..."
ssh -T git@github.com 2>&1 | grep -q "dc-bond" || { echo "SSH auth failed"; exit 1; }

# clone repos
git clone https://github.com/dc-bond/nixos-configs.git ~/nixos-configs 2>/dev/null || (cd ~/nixos-configs && git pull)
git clone git@github.com:dc-bond/.password-store.git ~/.password-store 2>/dev/null || (cd ~/.password-store && git pull)

# verify pass works
pass show "hosts/${HOSTNAME}/age/private" >/dev/null || { echo "Pass access failed"; exit 1; }

# final confirmation
echo "WARNING: This will DESTROY all data on the target disk!"
read -p "Type yes to proceed: " CONFIRM
[[ "$CONFIRM" != "yes" ]] && exit 1

cd ~/nixos-configs
nix-shell ~/nixos-configs/scripts/bootstrap.nix --run "bootstrap-${HOSTNAME}"
'

echo "Done! Reboot, login, then run: sudo recoverSnap"