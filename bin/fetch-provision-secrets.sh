#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Materialize the provisioning secrets for a host while the vault is
# reachable, so the provision scripts can run without Bitwarden. Needed for
# gate-jp, whose wipe takes down the reverse proxy in front of the vault
# itself (vault.qyrnl.com terminates on gate-jp's caddy).
#
# Output layout, consumed by `provision-linode <ip> <host> [staging] <dir>`:
#   <dir>/root.key                    LUKS passphrase (0600)
#   <dir>/ssh_host_ed25519_key        host key (0600)
#   <dir>/ssh_host_ed25519_key.pub    host key (0644)
#
# The directory holds live key material: delete it as soon as the host is
# provisioned.

if test $# -ne 2; then
  >&2 echo "Illegal number of parameters: expected 2, got $#"
  >&2 echo "Usage: $0 <hostname> <output-dir>"
  exit 1
fi

TARGET_HOST="${1,,}"
OUTPUT_DIR="$2"

log_info() {
  echo -e "\033[32;1mINFO\033[0m: $1"
}

install -d -m 700 "$OUTPUT_DIR"

cleanup() {
  log_info "Locking password vault…"
  bw lock
}
trap cleanup EXIT

log_info "Syncing password vault…"
bw sync

log_info "Unlocking password vault…"
BW_SESSION=$(bw unlock --raw)
export BW_SESSION

log_info "Fetching root disk encryption key…"
ROOT_DISK_ENCRYPTION_KEYCHAIN=$(bw get item "Homelab ZFS Root Encryption Passphrases")
jq -r ".fields[] | select(.name==\"$TARGET_HOST\") | .value" \
  <<<"$ROOT_DISK_ENCRYPTION_KEYCHAIN" >"$OUTPUT_DIR/root.key"
chmod 600 "$OUTPUT_DIR/root.key"

log_info "Fetching ssh_host_ed25519_key key pair…"
SSH_HOST_KEYCHAIN=$(bw get item "ssh_host_ed25519_key $TARGET_HOST")
jq -r '.sshKey.publicKey' <<<"$SSH_HOST_KEYCHAIN" >"$OUTPUT_DIR/ssh_host_ed25519_key.pub"
jq -r '.sshKey.privateKey' <<<"$SSH_HOST_KEYCHAIN" >"$OUTPUT_DIR/ssh_host_ed25519_key"
chmod 644 "$OUTPUT_DIR/ssh_host_ed25519_key.pub"
chmod 600 "$OUTPUT_DIR/ssh_host_ed25519_key"

log_info "Secrets for $TARGET_HOST staged in $OUTPUT_DIR — delete after provisioning."
exit 0
