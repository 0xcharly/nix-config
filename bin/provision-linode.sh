#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Ensure that the script is passed two or three arguments.
if test $# -lt 2 || test $# -gt 3; then
  >&2 echo "Illegal number of parameters: expected 2 or 3, got $#"
  >&2 echo "Usage: $0 <ip-addr> <hostname> [staging-dir]"
  exit 1
fi

REMOTE_ADDR="$1"
TARGET_HOST="${2,,}"
STAGING_DIR="${3:-}"

log_info() {
  echo -e "\033[32;1mINFO\033[0m: $1"
}

if test -n "$STAGING_DIR" && ! test -d "$STAGING_DIR/persist"; then
  >&2 echo "Staging dir '$STAGING_DIR' has no persist/ subtree."
  exit 1
fi

# Create temporary directories.
#
# extra_system_files carries ONLY the SSH host keys: nixos-anywhere extracts
# --extra-files with `tar --no-same-owner`, so everything in it lands
# root-owned on the target — correct for host keys, fatal for pre-seeded
# service state. The [staging-dir] state tree is instead pushed separately
# after the install phase (see below), ownership preserved.
extra_system_files=$(mktemp -d)
disk_encryption_key_files=$(mktemp -d)

# Cleanup temporary data and sessions on exit.
cleanup() {
  # Delete temporary directories. A user-provided staging tree is kept: it is
  # the operator's to retain (and reuse on a retry) or delete.
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
BW_SESSION=$(bw unlock --raw)
export BW_SESSION # Open a new password session.

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

# Decrypt root encryption passphrase from the password store.
load_root_encryption_key() {
  log_info "Loading root disk encryption key…"

  output_path="$disk_encryption_key_files/root.key"

  install -d -m 700 "$(dirname "$output_path")"
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

  # Host keys live on /persist (services.openssh.hostKeys points there):
  # nixos-anywhere extracts --extra-files over the mounted target root, where
  # disko has /persist mounted.
  output_path="$extra_system_files/persist/etc/ssh/$key_name"

  install -d -m 755 "$(dirname "$output_path")"
  get_ssh_host_key "$SSH_HOST_KEYCHAIN" 'public' >"$output_path.pub"
  get_ssh_host_key "$SSH_HOST_KEYCHAIN" 'private' >"$output_path"

  # Restrict file ACLs so sshd will accept the keys.
  chmod 644 "$output_path.pub"
  chmod 600 "$output_path"
}

# Decrypt our private keys from the password store and copy them to the temporary directory.
log_info "Loading target host keys…"
load_ssh_host_key "ssh_host_ed25519_key"

# Setup installation SSH options.
nixos_anywhere_ssh_options=(
  --ssh-option "PubkeyAuthentication=yes"
  --ssh-option "UserKnownHostsFile=/dev/null"
  --ssh-option "StrictHostKeyChecking=no"
)
# Same options, plain-ssh form, for the state push below.
plain_ssh_options=(
  -o "PubkeyAuthentication=yes"
  -o "UserKnownHostsFile=/dev/null"
  -o "StrictHostKeyChecking=no"
)

# With a staging tree to push, stop before the reboot phase: the state must
# land on the mounted target filesystems first. First boot is final state.
phase_options=()
if test -n "$STAGING_DIR"; then
  phase_options+=(--phases kexec,disko,install)
fi

# Build and deploy the new system to the remote machine!
#
# The target only needs to be a running Linux with root SSH: nixos-anywhere
# kexecs into the custom installer image (covers both in-place wipes of
# running NixOS and fresh Linodes booted from any stock distro image).
# --build-on local: the 1GB→2GB-resized Nanodes are too small to build.
log_info "Deploying new system…"
nix run github:nix-community/nixos-anywhere -- \
  "${nixos_anywhere_ssh_options[@]}" \
  "${disk_encryption_keys[@]}" \
  "${phase_options[@]}" \
  --build-on local \
  --kexec https://public.xn--7ck8cva5eb.com/nixos-kexec.tar.gz \
  --extra-files "$extra_system_files" \
  --flake ".#$TARGET_HOST" \
  --target-host "root@$REMOTE_ADDR"

if test -n "$STAGING_DIR"; then
  # Push the pre-seeded state root-to-root with numeric ownership preserved:
  # /var/lib/nixos travels in the tree, so the new install allocates the same
  # uids/gids and ownership is correct by construction — no post-boot chown
  # pass. `sudo` on the local end: the tree was built as root and contains
  # 0700 root-owned directories.
  log_info "Pushing pre-seeded state from $STAGING_DIR…"
  sudo tar --numeric-owner -cpf - -C "$STAGING_DIR" . |
    ssh "${plain_ssh_options[@]}" "root@$REMOTE_ADDR" \
      'tar --numeric-owner -xpf - -C /mnt && chmod 755 /mnt && chown 0:0 /mnt /mnt/persist'

  log_info "Rebooting target…"
  # shellcheck disable=SC2029
  ssh "${plain_ssh_options[@]}" "root@$REMOTE_ADDR" \
    'umount -Rv /mnt; nohup sh -c "sleep 2 && reboot" >/dev/null 2>&1 &'
fi

# System install completion notice.
echo -e "System installation \033[32;1mcomplete\033[0m. System rebooting."
echo -e "\033[33;1mImportant\033[0m: Remove the temporary plan resize (downsize back to Nanode) once smoke checks pass! "
echo
echo "じゃあね。"

# We're done.
exit 0
