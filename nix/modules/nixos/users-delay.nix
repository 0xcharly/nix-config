{flake, ...}: {
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [flake.modules.nixos.users-common];

  options.node.users.delay = with lib; {
    ssh = {
      authorizeTailscaleInternalKey = mkEnableOption ''
        Whether to add the tailscale-internal public SSH key to the user's authorized_keys.
      '';
      authorizeTailscalePublicKey = mkEnableOption ''
        Whether to add the tailscale-internal public SSH key to the user's authorized_keys.
      '';
    };
  };

  config = let
    cfg = config.node.users.delay;
  in {
    # Main shell.
    programs.fish.enable = true;

    users = {
      # Creates the group `delay`.
      groups.delay = {};

      # Creates the user `delay`.
      users.delay = {
        isNormalUser = true;
        home = "/home/delay";
        group = "delay";
        extraGroups = ["wheel"];
        shell = pkgs.fish;
        # Create a hashed password with `nix-shell -p mkpasswd --run "mkpasswd -m yescrypt"`
        hashedPasswordFile = config.age.secrets."passwd/delay".path;

        openssh.authorizedKeys.keys =
          # This key is not used on a daily basis (Tailscale SSH is preferred), but
          # exists as a fallback.
          lib.optionals cfg.ssh.authorizeTailscaleInternalKey [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIi4b0qJVhTYPykLFKx89tighmRFmYKV4AkkEqkBeAiG tailscale-internal"
          ]
          # Tailscale nodes opened to the public internet accept a different key. The
          # above one should be limited to internal connections only, while this one
          # should be limited to external connections only (such that it can be
          # revoked without impacting internal connections).
          ++ lib.optionals cfg.ssh.authorizeTailscalePublicKey [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHjAzWFwcBBC1brhZPmtHs39UEQU0IRtlcS/BEwfmqFj tailscale-public"
          ];
      };
    };
  };
}
