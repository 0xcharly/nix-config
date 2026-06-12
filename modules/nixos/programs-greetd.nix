{
  flake.nixosModules.programs-greetd =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.node.services.loginManager = with lib; {
        command = mkOption {
          type = types.str;
          description = "The session command to run on login.";
          default = "${getExe config.programs.uwsm.package} start -eD Hyprland hyprland-uwsm.desktop";
        };
      };

      config =
        let
          cfg = config.node.services.loginManager;
        in
        {
          programs = {
            hyprland = {
              enable = true;
              withUWSM = true;
              package = pkgs.hyprland;
              portalPackage = pkgs.xdg-desktop-portal-hyprland;
            };

            uwsm = {
              enable = true;
              waylandCompositors.hyprland = {
                prettyName = "Hyprland";
                comment = "Hyprland compositor managed by UWSM";
                binPath = "/run/current-system/sw/bin/start-hyprland";
              };
            };
          };

          # Greetd Login Manager daemon with tuigreet greeter
          services.greetd = {
            enable = true;
            useTextGreeter = true;
            settings.default_session.command = ''
              ${lib.getExe pkgs.tuigreet} --time --cmd "${cfg.command}"
            '';
          };

          # Required for graphical interfaces (X or Wayland) to work
          security.polkit.enable = true;
        };
    };
}
