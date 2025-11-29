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

ping -c 1 "$TARGET_HOST-initrd" >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  log_error "Could not reach $TARGET_HOST… exiting."
  exit 1
else
  log_info "$TARGET_HOST is online!"
fi

# Setup installation SSH options.
ssh_options=(
  -tt
  -l root
  -o "IdentityFile=/run/agenix/keys/nixos_remote_unlock_ed25519_key"
  -o "PubkeyAuthentication=yes"
  -o "UserKnownHostsFile=/dev/null"
  -o "StrictHostKeyChecking=no"
)

log_info "Unlocking system…"
ssh "${ssh_options[@]}" "$TARGET_HOST-initrd"
