{ self, ... }:
{
  flake.homeModules.programs-wayland-quickshell =
    { config, lib, pkgs, ... }:
    {
      imports = with self.homeModules; [
        colors-arcshell
        programs-arcshell
      ];

      options.node.wayland.arcshell = with lib; {
        modules = {
          power = mkEnableOption "Enable the power management module";
        };
      };

      config =
        let
          cfg = config.node.wayland.arcshell;
        in
        {
          programs.arcshell = {
            enable = true;
            systemd.enable = true;
            settings.theme.hud.bar.power.enable = cfg.modules.power;
            settings.services.launcher.launchPrefix = [ config.node.wayland.uwsm-wrapper.prefix ];
            settings.services.launcher.emojiData = "${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt";
            settings.services.launcher.unicodeData = "${pkgs.unicode-character-database}/share/unicode/UnicodeData.txt";
            settings.services.launcher.qalcPath = "${pkgs.libqalculate}/bin/qalc";
            settings.services.launcher.terminalCommand =
              let
                terminal = config.user.terminal.default;
                # Flag that makes the terminal exec the argv that follows it.
                # kitty takes the command as positional argv with no flag;
                # unknown terminals get the kitty treatment.
                execFlags = {
                  ghostty = [ "-e" ];
                  kitty = [ ];
                };
              in
              [ (lib.getExe terminal.package) ] ++ (execFlags.${terminal.name} or [ ]);
          };
        };
    };
}
