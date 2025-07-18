#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Ensure that the script is passed a single argument.
if test $# -ne 1; then
  >&2 echo "Illegal number of parameters: expected 1, got $#"
  >&2 echo "Usage: $0 <ip-addr>"
  exit 1
fi

REMOTE_ADDR="$1"

# Create a temporary directory
extra_system_files=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$extra_system_files"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys
install -d -m755 "$extra_system_files/etc/ssh"

# Export SSH keys in the correct format.
OP_READ_OPTS="?ssh-format=openssh"

# Decrypt your private key from the password store and copy it to the temporary directory
op read "op://Private/Linode ssh_host_ed25519_key/public key" >"$extra_system_files/etc/ssh/ssh_host_ed25519_key.pub"
op read "op://Private/Linode ssh_host_ed25519_key/private key$OP_READ_OPTS" >"$extra_system_files/etc/ssh/ssh_host_ed25519_key"
op read "op://Private/Linode ssh_host_rsa_key/public key" >"$extra_system_files/etc/ssh/ssh_host_rsa_key.pub"
op read "op://Private/Linode ssh_host_rsa_key/private key$OP_READ_OPTS" >"$extra_system_files/etc/ssh/ssh_host_rsa_key"

# Set the correct permissions so sshd will accept the key
chmod 600 "$extra_system_files/etc/ssh/ssh_host_ed25519_key.pub"
chmod 600 "$extra_system_files/etc/ssh/ssh_host_ed25519_key"
chmod 600 "$extra_system_files/etc/ssh/ssh_host_rsa_key.pub"
chmod 600 "$extra_system_files/etc/ssh/ssh_host_rsa_key"

# Build and deploy the new system to the remote machine!
nix run github:nix-community/nixos-anywhere -- \
  --disko-mode disko \
  --extra-files "$extra_system_files" \
  --ssh-option "PubkeyAuthentication=yes" \
  --ssh-option "UserKnownHostsFile=/dev/null" \
  --ssh-option "StrictHostKeyChecking=no" \
  --flake '.#linode' \
  --target-host "nixos@$REMOTE_ADDR"

# System install completion notice.
echo -e "System installation \033[32;1mcomplete\033[0m. System rebooting."
echo -e "\033[33;1mImportant\033[0m: Reboot the system with the correct configuration! "
echo

for i in {10..1}; do
  echo -ne "$i… \r"
  sleep 1
done

echo "じゃあね。"

# We're done.
exit 0
