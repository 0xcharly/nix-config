{ moduleWithSystem, self, ... }:
{
  # `wake` powers on nyx over LAN (WOL relayed through node-skl).
  # Only installed on trusted terminal hosts (via profile-hardware-workstation);
  # also exposed as a flake package: `nix run .#wake`.
  flake.homeModules.programs-wake = moduleWithSystem (
    perSystem@{ config, ... }:
    {
      home.packages = with perSystem.config.packages; [ wake ];
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.wake = pkgs.writeShellApplication {
        name = "wake";
        runtimeInputs = with pkgs; [
          gum
          iputils
          openssh
        ];
        text = ''
          # Wake nyx over LAN, relayed through node-skl: WOL magic packets are L2
          # broadcasts and do not route across subnets or the tailnet.
          #
          # Resume from suspend (S3) skips initrd entirely: the host simply comes
          # back online. Cold boot / hibernate stops at the LUKS prompt.

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
            log_info "$TARGET_HOST is already up, awaiting its LUKS passphrase at $TARGET_HOST-unlock."
            exit 0
          fi

          log_info "Sending magic packet for $MAC to $BROADCAST via $RELAY_HOST..."
          # Prefer the wakeonlan installed on the relay (programs-wakeonlan);
          # fall back to fetching it at runtime — slower, but survives the
          # package being dropped from node-skl. The nixpkgs registry entry is
          # pinned to the flake input on every host, so no channel fetch occurs.
          if ! ssh "$RELAY_HOST" -- "if command -v wakeonlan >/dev/null 2>&1; then wakeonlan -i $BROADCAST $MAC; else nix run nixpkgs#wakeonlan -- -i $BROADCAST $MAC; fi"; then
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
              log_info "$TARGET_HOST cold-booted into initrd and awaits its LUKS passphrase at $TARGET_HOST-unlock."
              exit 0
            fi
            if ((SECONDS >= deadline)); then
              log_error "Timed out waiting for $TARGET_HOST."
              log_error "If the packet had no effect, check on $TARGET_HOST: 'ethtool enp115s0 | grep Wake-on' (expect 'Wake-on: g'), and BIOS ErP / Wake-on-PCIe settings."
              exit 1
            fi
            sleep 2
          done
        '';
      };
    };
}
