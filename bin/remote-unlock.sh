#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Ensure that the script is passed a single argument.
if test $# -ne 1; then
  >&2 echo "Illegal number of parameters: expected 1, got $#"
  >&2 echo "Usage: $0 <hostname>"
  exit 1
fi

TARGET_HOST="${1,,}"

log_info() {
  echo -e "\033[32;1mINFO\033[0m: $1"
}

log_error() {
  echo -e "\033[33;1mINFO\033[0m: $1"
}

# Cleanup temporary data and sessions on exit.
cleanup() {
  # Close the password vault session.
  log_info "Locking password vault…"
  bw lock
}
trap cleanup EXIT

ping -c 1 "$TARGET_HOST-initrd" >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  log_error "Could not reach $TARGET_HOST… exiting."
  exit 1
else
  log_info "$TARGET_HOST is online!"
fi

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
  key_name="$1"

  echo -n "$ROOT_DISK_ENCRYPTION_KEYCHAIN" | jq -r ".fields[] | select(.name==\"$key_name\") | .value"
}

# Setup installation SSH options.
ssh_options=(
  -T
  -l root
  -o "IdentityFile=$XDG_RUNTIME_DIR/agenix/keys/nixos_remote_unlock_ed25519_key"
  -o "PubkeyAuthentication=yes"
  -o "UserKnownHostsFile=/dev/null"
  -o "StrictHostKeyChecking=no"
)

log_info "Unlocking system…"
get_disk_encryption_key "$TARGET_HOST" | ssh "${ssh_options[@]}" "$TARGET_HOST-initrd"
