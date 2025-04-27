#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Ensure that the script is passed a single argument.
if test $# -ne 2; then
  >&2 echo "Illegal number of parameters: expected 2, got $#"
  >&2 echo "Usage: $0 <ip-addr> <hostname>"
  exit 1
fi

REMOTE_ADDR="$1"
TARGET_HOST="$2"

# Create a temporary directory.
extra_system_files=$(mktemp -d)
temp_setup_secrets=$(mktemp -d)

# Function to cleanup temporary directory on exit.
cleanup() {
  rm -rf "$extra_system_files"
  rm -rf "$temp_setup_secrets"
}
trap cleanup EXIT

# Create the directories where the secrets will be stored.
install -d -m755 "$temp_setup_secrets/run/agenix"
install -d -m755 "$temp_setup_secrets/run/agenix/zfs/tank/backups"
install -d -m755 "$temp_setup_secrets/run/agenix/zfs/tank/ayako"
install -d -m755 "$temp_setup_secrets/run/agenix/zfs/tank/delay"

# Decrypt our ZFS Pool encryption passphrases from the password store and copy them to the temporary directory.
NAS_VAULT_PATH="op://Private/NAS - ZFS Pool Encryption Passphrases"
op read "$NAS_VAULT_PATH/backups/ayako" >"$temp_setup_secrets/run/agenix/zfs/tank/backups/ayako.key"
op read "$NAS_VAULT_PATH/backups/dad" >"$temp_setup_secrets/run/agenix/zfs/tank/backups/dad.key"
op read "$NAS_VAULT_PATH/backups/delay" >"$temp_setup_secrets/run/agenix/zfs/tank/backups/delay.key"
op read "$NAS_VAULT_PATH/ayako/files" >"$temp_setup_secrets/run/agenix/zfs/tank/ayako/files.key"
op read "$NAS_VAULT_PATH/ayako/media" >"$temp_setup_secrets/run/agenix/zfs/tank/ayako/media.key"
op read "$NAS_VAULT_PATH/delay/beans" >"$temp_setup_secrets/run/agenix/zfs/tank/delay/beans.key"
op read "$NAS_VAULT_PATH/delay/files" >"$temp_setup_secrets/run/agenix/zfs/tank/delay/files.key"
op read "$NAS_VAULT_PATH/delay/media" >"$temp_setup_secrets/run/agenix/zfs/tank/delay/media.key"

# Copy the secrets to the host machine.
rsync -rv --no-p --no-g --no-o --stats --progress \
  -e "ssh -lroot -o IdentityFile=~/.ssh/recovery-iso -o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" \
  "$temp_setup_secrets/" "root@$REMOTE_ADDR:/"

# Create the directory where sshd expects to find the host keys.
install -d -m755 "$extra_system_files/etc/ssh"

# Decrypt our private keys from the password store and copy them to the temporary directory.
op read "op://Private/${TARGET_HOST^} ssh_host_ed25519_key/public key" >"$extra_system_files/etc/ssh/ssh_host_ed25519_key.pub"
op read "op://Private/${TARGET_HOST^} ssh_host_ed25519_key/private key" >"$extra_system_files/etc/ssh/ssh_host_ed25519_key"
op read "op://Private/${TARGET_HOST^} ssh_host_rsa_key/public key" >"$extra_system_files/etc/ssh/ssh_host_rsa_key.pub"
op read "op://Private/${TARGET_HOST^} ssh_host_rsa_key/private key" >"$extra_system_files/etc/ssh/ssh_host_rsa_key"

# Set the correct permissions so sshd will accept the key.
chmod 600 "$extra_system_files/etc/ssh/ssh_host_ed25519_key.pub"
chmod 600 "$extra_system_files/etc/ssh/ssh_host_ed25519_key"
chmod 600 "$extra_system_files/etc/ssh/ssh_host_rsa_key.pub"
chmod 600 "$extra_system_files/etc/ssh/ssh_host_rsa_key"

# Build and deploy the new system to the remote machine!
# The --disko-mode option is required to work around a recent bug in
# nixos-anywhere: https://github.com/nix-community/nixos-anywhere/issues/508.
nix run github:nix-community/nixos-anywhere -- \
  --disko-mode disko \
  --extra-files "$extra_system_files" \
  --ssh-option "IdentityFile=~/.ssh/recovery-iso" \
  --ssh-option "PubkeyAuthentication=yes" \
  --ssh-option "UserKnownHostsFile=/dev/null" \
  --ssh-option "StrictHostKeyChecking=no" \
  --flake ".#$TARGET_HOST" \
  --target-host "root@$REMOTE_ADDR"

# System install completion notice.
echo -e "System installation \033[32;1mcomplete\033[0m. System rebooting."
echo -e "\033[33;1mImportant\033[0m: Make sure to remove the installation media! "
echo
echo "じゃあね。"

# We're done.
exit 0
