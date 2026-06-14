{ self, inputs, ... }:
{
  flake.homeModules.programs-wayland-quickshell =
    { config, lib, ... }:
    {
      imports = [
        inputs.nix-config-colorscheme.homeModules.arcshell
        self.homeModules.programs-arcshell
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
          };
        };
    };
}
