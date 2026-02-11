{
  config,
  lib,
  pkgs',
  ...
}:
{
  options.node.services.loginManager.autoLogin = with lib; {
    user = mkOption {
      type = types.str;
      default = "delay";
      description = "The user to auto-login";
    };
  };

  config =
    let
      cfg = config.node.services.loginManager.autoLogin;
    in
    {
      # Greetd Login Manager daemon with tuigreet greeter
      services = {
        greetd.settings = {
          initial_session = {
            command = "${lib.getExe config.programs.uwsm.package} start default";
            inherit (cfg) user;
          };
        };

        gnome.gnome-keyring.enable = true;
      };

      security = {
        # Auto unlock default keyring on login
        pam.services = {
          # PAM Configuration
          # The key insight: greetd's initial_session (autologin) doesn't call PAM auth,
          # so we inject the LUKS password during the session phase instead using pam_fde_boot_pw.
          # See: https://lists.sr.ht/~kennylevinsen/greetd-devel/%3CCAOVAYzup8rEVtq1q4Bw5jZS=tf1WyeWwhHB0jgHvoZyhUuGZeg@mail.gmail.com%3E
          # See: https://discourse.nixos.org/t/automatically-unlocking-the-gnome-keyring-using-luks-key-with-greetd-and-hyprland/54260/10
          greetd = {
            # Add pam_fde_boot_pw rule BEFORE gnome_keyring in the session phase
            # This ensures the LUKS password is injected before gnome-keyring tries to unlock
            # Order 12600: gnome_keyring is typically at 12700, so this runs before it
            rules.session.fde_boot_pw = {
              order = 12600;
              enable = true;
              control = "optional";
              # TODO: nixpkgs/26.05 - use package from stable channel.
              modulePath = "${pkgs'.pam_fde_boot_pw}/lib/security/pam_fde_boot_pw.so";
              args = [ "inject_for=gkr" ];
            };
          };

          greetd-password.enableGnomeKeyring = true;
          hyprland.enableGnomeKeyring = true;
          login.enableGnomeKeyring = true;
        };
      };

      # Allow LUKS password to be used to unlock GNOME keyring
      boot.initrd.systemd.enable = true;
    };
}
