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
TARGET_HOST="${2,,}"

log_info() {
  echo -e "\033[32;1mINFO\033[0m: $1"
}

# Create temporary directories.
extra_system_files=$(mktemp -d)
disk_encryption_key_files=$(mktemp -d)

# Cleanup temporary data and sessions on exit.
cleanup() {
  # Delete temporary directories.
  log_info "Cleaning build artifacts…"
  rm -rf "$extra_system_files"
  rm -rf "$disk_encryption_key_files"

  # Close the password vault session.
  log_info "Locking password vault…"
  bw lock
}
trap cleanup EXIT

log_info "Syncing password vault…"
bw sync # Sync vault.

log_info "Unlocking password vault…"
BW_SESSION=$(bw unlock --raw); export BW_SESSION # Open a new password session.

# Fetch keys in bulk to speed up lookups.
log_info "Loading disk encryption keys…"
ROOT_DISK_ENCRYPTION_KEYCHAIN_NAME="Homelab ZFS Root Encryption Passphrases"
ROOT_DISK_ENCRYPTION_KEYCHAIN=$(bw get item "$ROOT_DISK_ENCRYPTION_KEYCHAIN_NAME")

# Extract the given key from the top level Bitwarden entry value.
get_disk_encryption_key() {
  keychain="$1"
  key_name="$2"

  echo "$keychain" | jq -r ".fields[] | select(.name==\"$key_name\") | .value"
}

# Decrypt ZFS root encryption passphrase from the password store.
load_root_encryption_key() {
  log_info "Loading root dataset encryption key…"

  output_path="$disk_encryption_key_files/zfs/root.key"

  install -d -m 700 $(dirname "$output_path")
  get_disk_encryption_key "$ROOT_DISK_ENCRYPTION_KEYCHAIN" "$TARGET_HOST" >"$output_path"

  disk_encryption_keys+=(--disk-encryption-keys /tmp/root-disk-encryption.key "$output_path")
}

load_root_encryption_key

# Extract the given key from the top level Bitwarden entry value.
# `key_type` is either "private" or "public".
get_ssh_host_key() {
  keychain="$1"
  key_type="$2"

  echo "$keychain" | jq -r ".sshKey.${key_type}Key"
}

load_ssh_host_key() {
  key_name="$1"
  log_info "Loading $key_name key pair…"

  SSH_HOST_KEYCHAIN=$(bw get item "$key_name $TARGET_HOST")

  output_path="$extra_system_files/etc/ssh/$key_name"

  install -d -m 755 $(dirname "$output_path")
  get_ssh_host_key "$SSH_HOST_KEYCHAIN" 'public' >"$output_path.pub"
  get_ssh_host_key "$SSH_HOST_KEYCHAIN" 'private' >"$output_path"

  # Restrict file ACLs so sshd will accept the keys.
  chmod 644 "$output_path.pub"
  chmod 600 "$output_path"
}

# Decrypt our private keys from the password store and copy them to the temporary directory.
log_info "Loading target host keys…"
load_ssh_host_key "ssh_host_ed25519_key"
load_ssh_host_key "ssh_host_ed25519_key-initrd"

# Setup installation SSH options.
ssh_options=(
  --ssh-option "IdentityFile=$XDG_RUNTIME_DIR/agenix/keys/nixos_recovery_ed25519_key"
  --ssh-option "PubkeyAuthentication=yes"
  --ssh-option "UserKnownHostsFile=/dev/null"
  --ssh-option "StrictHostKeyChecking=no"
)

# Build and deploy the new system to the remote machine!
log_info "Deploying new system…"
nix run github:nix-community/nixos-anywhere -- \
  "${ssh_options[@]}" \
  "${disk_encryption_keys[@]}" \
  --build-on-remote \
  --extra-files "$extra_system_files" \
  --flake ".#$TARGET_HOST" \
  --target-host "root@$REMOTE_ADDR"

# System install completion notice.
echo -e "System installation \033[32;1mcomplete\033[0m. System rebooting."
echo -e "\033[33;1mImportant\033[0m: Make sure to remove the installation media! "
echo
echo "じゃあね。"

# We're done.
exit 0
