{ moduleWithSystem, self, ... }:
{
  # `wake` powers on nyx over LAN (WOL relayed through node-skl), chaining
  # into `unlock` on cold boot. `unlock` answers a host's initrd LUKS
  # prompt over hoopsnake.
  # Only installed on trusted terminal hosts (via profile-hardware-workstation);
  # also exposed as flake packages: `nix run .#wake` / `nix run .#unlock`.
  flake.homeModules.programs-wake = moduleWithSystem (
    perSystem@{ config, ... }:
    {
      home.packages = with perSystem.config.packages; [
        unlock
        wake
      ];
    }
  );

  perSystem =
    { config, pkgs, ... }:
    {
      packages.wake = pkgs.writeShellApplication {
        name = "wake";
        runtimeInputs = [
          config.packages.unlock
          pkgs.gum
          pkgs.iputils
          pkgs.openssh
        ];
        text = ''
          # Wake nyx over LAN, relayed through node-skl: WOL magic packets are L2
          # broadcasts and do not route across subnets or the tailnet.
          #
          # Resume from suspend (S3) skips initrd entirely: the host simply comes
          # back online. Cold boot / hibernate stops at the LUKS prompt, which is
          # answered by chaining into `unlock`.

          readonly TARGET_HOST=nyx
          readonly RELAY_HOST=node-skl
          readonly MAC="${self.lib.facts.lan.nyx.mac}"
          readonly BROADCAST="${self.lib.facts.lan.nyx.broadcast}"
          readonly TIMEOUT_SECS=180

          log_info() {
            gum log --time=datetime --level=info "$@"
          }

          log_error() {
            gum log --time=datetime --level=error "$@"
          }

          is_up() {
            ping -c 1 -W 2 "$1" >/dev/null 2>&1
          }

          if is_up "$TARGET_HOST"; then
            log_info "$TARGET_HOST is already online."
            exit 0
          fi

          if is_up "$TARGET_HOST-unlock"; then
            log_info "$TARGET_HOST is already up, awaiting its LUKS passphrase."
          else
            log_info "Sending magic packet for $MAC to $BROADCAST via $RELAY_HOST..."
            # Prefer the wakeonlan installed on the relay (programs-wakeonlan);
            # fall back to fetching it at runtime — slower, but survives the
            # package being dropped from node-skl. The nixpkgs registry entry is
            # pinned to the flake input on every host, so no channel fetch occurs.
            # Wrapped in `sh -c`: the remote command runs under the login shell
            # (fish for delay), which does not parse `if …; then`.
            if ! ssh "$RELAY_HOST" -- "sh -c 'if command -v wakeonlan >/dev/null 2>&1; then wakeonlan -i $BROADCAST $MAC; else nix run nixpkgs#wakeonlan -- -i $BROADCAST $MAC; fi'"; then
              log_error "Could not send the magic packet through $RELAY_HOST."
              exit 1
            fi

            log_info "Waiting for $TARGET_HOST to come up (timeout: $TIMEOUT_SECS seconds)..."
            deadline=$((SECONDS + TIMEOUT_SECS))
            while true; do
              if is_up "$TARGET_HOST"; then
                log_info "$TARGET_HOST is online (resumed from suspend)."
                exit 0
              fi
              if is_up "$TARGET_HOST-unlock"; then
                log_info "$TARGET_HOST cold-booted into initrd."
                break
              fi
              if ((SECONDS >= deadline)); then
                log_error "Timed out waiting for $TARGET_HOST."
                log_error "If the packet had no effect, check on $TARGET_HOST: 'ethtool enp115s0 | grep Wake-on' (expect 'Wake-on: g'), and BIOS ErP / Wake-on-PCIe settings."
                exit 1
              fi
              sleep 2
            done
          fi

          unlock "$TARGET_HOST"

          log_info "Waiting for $TARGET_HOST to finish booting..."
          deadline=$((SECONDS + TIMEOUT_SECS))
          until is_up "$TARGET_HOST"; do
            if ((SECONDS >= deadline)); then
              log_error "Timed out waiting for $TARGET_HOST after unlock."
              exit 1
            fi
            sleep 2
          done
          log_info "$TARGET_HOST is online."
        '';
      };

      packages.unlock = pkgs.writeShellApplication {
        name = "unlock";
        runtimeInputs = [
          pkgs.gum
          pkgs.iputils
          pkgs.openssh
        ];
        # SC2029: "$TARGET_HOST-unlock" is the ssh destination, not a remote
        # command — client-side expansion is by design.
        excludeShellChecks = [ "SC2029" ];
        text = ''
          # Answer a host's initrd LUKS prompt over its hoopsnake endpoint
          # (<host>-unlock on the tailnet). Feeds the passphrase from the
          # host-level agenix secret when deployed, else interactive.

          log_info() {
            gum log --time=datetime --level=info "$@"
          }

          log_error() {
            gum log --time=datetime --level=error "$@"
          }

          if test $# -ne 1; then
            log_error "Usage: unlock <hostname>"
            exit 1
          fi

          TARGET_HOST=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
          readonly TARGET_HOST
          readonly IDENTITY=/run/agenix/keys/nixos_remote_unlock_ed25519_key
          readonly PASSFILE="/run/agenix/luks/$TARGET_HOST.passphrase"

          if ! test -r "$IDENTITY"; then
            log_error "Missing or unreadable $IDENTITY."
            log_error "Remote unlock only works from a trusted terminal host (fwk, nyx, term-x1p) with luks-remote-unlock deployed."
            exit 1
          fi

          if ! ping -c 1 -W 2 "$TARGET_HOST-unlock" >/dev/null 2>&1; then
            log_error "Could not reach $TARGET_HOST-unlock. Is $TARGET_HOST powered on and waiting in initrd?"
            exit 1
          fi

          ssh_options=(
            -tt
            -l root
            -o "IdentityFile=$IDENTITY"
            -o "PubkeyAuthentication=yes"
            -o "RequestTTY=force"
            -o "StrictHostKeyChecking=no"
            -o "UserKnownHostsFile=/dev/null"
          )

          if test -r "$PASSFILE"; then
            log_info "Unlocking $TARGET_HOST with the stored passphrase..."
            printf '%s\n' "$(cat "$PASSFILE")" | ssh "''${ssh_options[@]}" "$TARGET_HOST-unlock"
          else
            log_info "No stored passphrase for $TARGET_HOST; unlocking interactively..."
            ssh "''${ssh_options[@]}" "$TARGET_HOST-unlock"
          fi
        '';
      };
    };
}
