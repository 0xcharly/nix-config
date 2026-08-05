#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# The in-place wipe dance for a Linode migrating to btrfs: delete the legacy
# swap disk, grow the root disk to fill the plan, and boot the target ready
# for `provision-linode`.
#
# Requires an authenticated linode-cli (`linode-cli configure` beforehand).
# Every step is idempotent: a partial failure must never strand a host
# mid-dance; re-running skips completed steps.

if test $# -ne 2; then
  >&2 echo "Illegal number of parameters: expected 2, got $#"
  >&2 echo "Usage: $0 <linode-id> <host>"
  exit 1
fi

LINODE_ID="$1"
TARGET_HOST="${2,,}"

# 25600MB = the Nanode's exact storage ceiling. Boundary-tested on the trial
# clone (2026-08-05): `disk-resize --size 25600` accepted, and Linode's
# downsize rule is total disk allocation ≤ target plan storage, so 25600
# downsizes back to a Nanode exactly. The earlier 25088 safety buffer is
# retired.
readonly ROOT_DISK_SIZE_MB=25600

log_info() {
  echo -e "\033[32;1mINFO\033[0m: $1"
}

log_error() {
  >&2 echo -e "\033[31;1mERROR\033[0m: $1"
}

confirm() {
  read -r -p "$1 [y/N] " answer
  case "$answer" in
  [yY]*) return 0 ;;
  *) return 1 ;;
  esac
}

# Operator gate between steps: linode-cli returns before its queued event
# (shutdown/delete/resize/boot) settles, and polled statuses can read stale
# ("ready" before the resize event even starts). Each step therefore pauses
# until the operator confirms the observed state (disks-list printout / Cloud
# Manager events) before the next mutation is issued.
pause() {
  read -r -p "$1 Press enter to continue. "
}

linode_status() {
  linode-cli linodes view "$LINODE_ID" --json | jq -r '.[0].status'
}

wait_for_status() {
  want="$1"
  while true; do
    status=$(linode_status)
    if test "$status" = "$want"; then
      break
    fi
    log_info "Linode $LINODE_ID is $status; waiting for $want…"
    sleep 5
  done
}

wait_for_disk_ready() {
  disk_id="$1"
  while true; do
    disk_status=$(linode-cli linodes disk-view "$LINODE_ID" "$disk_id" --json | jq -r '.[0].status')
    if test "$disk_status" = "ready"; then
      break
    fi
    log_info "Disk $disk_id is $disk_status; waiting…"
    sleep 5
  done
}

echo "Pre-flight reminders:"
echo "  - The plan must already be resized to ≥4GB RAM: kexec_load EINVALs on"
echo "    2GB — the ~950MB installer initrd does not fit the segment layout"
echo "    (trial-tested 2026-08-05). Downsize back to Nanode after smoke checks."
echo "  - The clone (emergency rollback) must already exist and be powered off."
if ! confirm "Lish access confirmed?"; then
  log_error "Confirm Lish console access before wiping a remote host."
  exit 1
fi

# Step 1: enumerate disks; auto-detect the swap and root disk IDs.
log_info "Disks on Linode $LINODE_ID:"
linode-cli linodes disks-list "$LINODE_ID"

disks_json=$(linode-cli linodes disks-list "$LINODE_ID" --json)
SWAP_DISK_ID=$(jq -r '[.[] | select(.filesystem == "swap" or (.label | ascii_downcase) == "swap")][0].id // empty' <<<"$disks_json")
ROOT_DISK_ID=$(jq -r '[.[] | select(.filesystem != "swap" and ((.label | ascii_downcase) != "swap"))][0].id // empty' <<<"$disks_json")
ROOT_DISK_SIZE=$(jq -r '[.[] | select(.filesystem != "swap" and ((.label | ascii_downcase) != "swap"))][0].size // 0' <<<"$disks_json")

if test -z "$ROOT_DISK_ID"; then
  log_error "Could not identify the root disk. Aborting."
  exit 1
fi

if test -z "$SWAP_DISK_ID"; then
  # Already deleted on a prior run.
  log_info "No swap disk found (already deleted?); continuing."
else
  log_info "Swap disk: $SWAP_DISK_ID; root disk: $ROOT_DISK_ID (${ROOT_DISK_SIZE}MB)."
fi

pause "Confirm the detected disk IDs match the disks-list printout above."

# Step 2: power off.
if test "$(linode_status)" = "offline"; then
  log_info "Linode $LINODE_ID is already offline."
else
  log_info "Shutting down Linode $LINODE_ID…"
  linode-cli linodes shutdown "$LINODE_ID"
  wait_for_status offline
fi
pause "Confirm the Linode shows offline (shutdown event completed)."

# Step 3: delete the swap disk, grow the root disk.
if test -n "$SWAP_DISK_ID"; then
  log_info "Deleting swap disk $SWAP_DISK_ID…"
  linode-cli linodes disk-delete "$LINODE_ID" "$SWAP_DISK_ID"
  pause "Confirm the swap disk deletion event completed (disk gone from disks-list)."
fi

if test "$ROOT_DISK_SIZE" -ge "$ROOT_DISK_SIZE_MB"; then
  log_info "Root disk already ${ROOT_DISK_SIZE}MB (≥${ROOT_DISK_SIZE_MB}MB); skipping resize."
else
  log_info "Resizing root disk $ROOT_DISK_ID to ${ROOT_DISK_SIZE_MB}MB…"
  linode-cli linodes disk-resize "$LINODE_ID" "$ROOT_DISK_ID" --size "$ROOT_DISK_SIZE_MB"
  wait_for_disk_ready "$ROOT_DISK_ID"
  pause "Confirm the root disk shows ${ROOT_DISK_SIZE_MB}MB (resize event completed)."
fi

# Step 4: config profile.
pause "Update the Linode config profile if it referenced the swap disk."

# Step 5: boot and hand off to the provisioning script.
if test "$(linode_status)" = "running"; then
  log_info "Linode $LINODE_ID is already running."
else
  log_info "Booting Linode $LINODE_ID…"
  linode-cli linodes boot "$LINODE_ID"
  wait_for_status running
fi
pause "Confirm the Linode shows running (boot event completed)."

log_info "Waiting for SSH…"
REMOTE_ADDR=$(linode-cli linodes view "$LINODE_ID" --json | jq -r '.[0].ipv4[0]')
until nc -z -w 5 "$REMOTE_ADDR" 22 2>/dev/null; do
  sleep 5
done

log_info "Linode $LINODE_ID is up at $REMOTE_ADDR. Next:"
echo "  provision-linode $REMOTE_ADDR $TARGET_HOST [staging-dir]"

exit 0
