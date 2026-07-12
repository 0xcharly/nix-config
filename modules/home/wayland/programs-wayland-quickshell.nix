{ self, ... }:
{
  flake.homeModules.programs-wayland-quickshell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = with self.homeModules; [
        colors-arcshell
        programs-arcshell
      ];

      options.node.wayland.arcshell = with lib; {
        modules = {
          power = mkEnableOption "Enable the power management module";
          powerProfile = mkEnableOption "Enable the power profile indicator module" // {
            default = true;
          };
          vpn = mkEnableOption "Enable the VPN egress check module";
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
            settings.theme.hud.bar = {
              power.enable = cfg.modules.power;
              powerProfile.enable = cfg.modules.powerProfile;
              vpn.enable = cfg.modules.vpn;
            };
            settings.services.launcher = {
              launchPrefix = lib.mkDefault [ config.node.wayland.uwsm-wrapper.prefix ];
              emojiData = lib.mkDefault "${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt";
              unicodeData = lib.mkDefault "${pkgs.unicode-character-database}/share/unicode/UnicodeData.txt";
              qalcPath = lib.mkDefault "${pkgs.libqalculate}/bin/qalc";
              terminalCommand = lib.mkDefault (
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
                [ (lib.getExe terminal.package) ] ++ (execFlags.${terminal.name} or [ ])
              );
            };
          };
        };
    };
}
