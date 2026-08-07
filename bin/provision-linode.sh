#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Ensure that the script is passed two to four arguments.
if test $# -lt 2 || test $# -gt 4; then
  >&2 echo "Illegal number of parameters: expected 2-4, got $#"
  >&2 echo "Usage: $0 <ip-addr> <hostname> [staging-dir] [secrets-dir]"
  >&2 echo "  secrets-dir: pre-fetched vault material (fetch-provision-secrets.sh);"
  >&2 echo "  skips Bitwarden entirely — required when the vault is unreachable"
  >&2 echo "  (gate-jp's wipe takes down the proxy in front of vault.qyrnl.com)."
  exit 1
fi

REMOTE_ADDR="$1"
TARGET_HOST="${2,,}"
STAGING_DIR="${3:-}"
SECRETS_DIR="${4:-}"

log_info() {
  echo -e "\033[32;1mINFO\033[0m: $1"
}

if test -n "$STAGING_DIR" && ! test -d "$STAGING_DIR/persist"; then
  >&2 echo "Staging dir '$STAGING_DIR' has no persist/ subtree."
  exit 1
fi
if test -n "$SECRETS_DIR"; then
  for f in root.key ssh_host_ed25519_key ssh_host_ed25519_key.pub; do
    if ! test -r "$SECRETS_DIR/$f"; then
      >&2 echo "Secrets dir '$SECRETS_DIR' is missing '$f' (build it with fetch-provision-secrets.sh)."
      exit 1
    fi
  done
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
  # the operator's to retain (and reuse on a retry) or delete; likewise the
  # secrets dir (delete it manually once the host is up).
  log_info "Cleaning build artifacts…"
  rm -rf "$extra_system_files"
  rm -rf "$disk_encryption_key_files"

  if test -z "$SECRETS_DIR"; then
    # Close the password vault session.
    log_info "Locking password vault…"
    bw lock
  fi
}
trap cleanup EXIT

if test -z "$SECRETS_DIR"; then
  log_info "Syncing password vault…"
  bw sync # Sync vault.

  log_info "Unlocking password vault…"
  BW_SESSION=$(bw unlock --raw)
  export BW_SESSION # Open a new password session.
fi

# Extract the given key from the top level Bitwarden entry value.
get_disk_encryption_key() {
  keychain="$1"
  key_name="$2"

  echo "$keychain" | jq -r ".fields[] | select(.name==\"$key_name\") | .value"
}

# Root encryption passphrase: from the pre-fetched secrets dir, or decrypted
# from the password store.
load_root_encryption_key() {
  log_info "Loading root disk encryption key…"

  output_path="$disk_encryption_key_files/root.key"

  install -d -m 700 "$(dirname "$output_path")"
  if test -n "$SECRETS_DIR"; then
    install -m 600 "$SECRETS_DIR/root.key" "$output_path"
  else
    ROOT_DISK_ENCRYPTION_KEYCHAIN=$(bw get item "Homelab ZFS Root Encryption Passphrases")
    get_disk_encryption_key "$ROOT_DISK_ENCRYPTION_KEYCHAIN" "$TARGET_HOST" >"$output_path"
  fi

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

  # Host keys live on /persist (services.openssh.hostKeys points there):
  # nixos-anywhere extracts --extra-files over the mounted target root, where
  # disko has /persist mounted.
  output_path="$extra_system_files/persist/etc/ssh/$key_name"

  install -d -m 755 "$(dirname "$output_path")"
  if test -n "$SECRETS_DIR"; then
    install -m 644 "$SECRETS_DIR/$key_name.pub" "$output_path.pub"
    install -m 600 "$SECRETS_DIR/$key_name" "$output_path"
    return
  fi

  SSH_HOST_KEYCHAIN=$(bw get item "$key_name $TARGET_HOST")
  get_ssh_host_key "$SSH_HOST_KEYCHAIN" 'public' >"$output_path.pub"
  get_ssh_host_key "$SSH_HOST_KEYCHAIN" 'private' >"$output_path"

  # Restrict file ACLs so sshd will accept the keys.
  chmod 644 "$output_path.pub"
  chmod 600 "$output_path"
}

# Load our private keys into the temporary directory.
log_info "Loading target host keys…"
load_ssh_host_key "ssh_host_ed25519_key"

# Setup installation SSH options.
#
# The recovery identity: the kexec installer (provisioning-base) authorizes
# exactly this key for root, with password auth off. The wipe flow kexecs the
# installer BEFORE this script runs (root over the public IP is impossible
# against a running fleet host — PermitRootLogin=no; root only exists over
# the tailnet via Tailscale SSH):
#   ssh root@<tailnet-ip> 'curl -L https://public.xn--7ck8cva5eb.com/nixos-kexec.tar.gz | tar -xzf - -C /root && /root/kexec/run'
# nixos-anywhere then detects the target is already an installer and skips
# its own kexec phase.
nixos_anywhere_ssh_options=(
  --ssh-option "IdentityFile=$XDG_RUNTIME_DIR/agenix/keys/nixos_recovery_ed25519_key"
  --ssh-option "PubkeyAuthentication=yes"
  --ssh-option "UserKnownHostsFile=/dev/null"
  --ssh-option "StrictHostKeyChecking=no"
)
# Same options, plain-ssh form, for the state push below.
plain_ssh_options=(
  -o "IdentityFile=$XDG_RUNTIME_DIR/agenix/keys/nixos_recovery_ed25519_key"
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
