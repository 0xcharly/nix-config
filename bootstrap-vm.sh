#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Ensure that the script is passed a single argument.
if test $# -ne 1; then
  >&2 echo "Illegal number of parameters: expected 1, got $#"
  >&2 echo "Usage: $0 <system-name>"
  exit 1
fi

# SSH config to use the correct key to fetch private GitHub repositories.
install -D -m 400 <(
  cat <<'EOF'
Host github.com
  User git
  IdentityFile ~/.ssh/github
  StrictHostKeyChecking no
  PubkeyAuthentication yes
  UserKnownHostsFile /dev/null
EOF
) $HOME/.ssh/config

NIX_OPTIONS="--option extra-experimental-features nix-command"
NIX_OPTIONS+=" --option extra-experimental-features flakes"
NIX_OPTIONS+=" --option accept-flake-config true"
NIX_OPTIONS+=" --show-trace"

SYSTEM_NAME="$1"
FLAKE_OPTIONS="--flake /nix-config#$SYSTEM_NAME"

# Create and mount filesystem.
# NOTE: the `--mode disko` option nukes all filesystems on system drive, then
# (re)create and mount partitions.
nix $NIX_OPTIONS run 'github:nix-community/disko' -- \
  --mode disko $FLAKE_OPTIONS

# Install system.
nixos-install $NIX_OPTIONS \
  --no-root-passwd $FLAKE_OPTIONS

# Reboot into new system.
shutdown --reboot +1

# Completion notice.
echo -e "System installation \033[32;1mcomplete\033[0m. Rebooting in 1 minute."
echo "After reboot, export your terminal's terminfo for best compatibility:"
echo
echo "  just ssh-copy-terminfo $SYSTEM_NAME"
echo
echo "じゃあね。"

# We're done.
exit 0
