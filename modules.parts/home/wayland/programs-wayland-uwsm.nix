{
  flake.homeModules.programs-wayland-uwsm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.node.wayland = with lib; {
        uwsm-wrapper = {
          package = mkPackageOption pkgs "app2unit" {
            extraDescription = ''
              The uwsm wrapper script to use to spawn new processes.

              Defaults to `app2unit`.

              `app2unit` is a faster alternative to `uwsm` (shell implementation
              over Python).
            '';
          };

          prefix = mkOption {
            type = types.str;
            default = "${lib.getExe config.node.wayland.uwsm-wrapper.package} -- ";
            description = ''
              The prefix command to spawn new processes.

              This is used by launchers to create new processes.
            '';
          };

          wrapper = mkOption {
            type = types.functionTo types.str;
            default = cmd: "${config.node.wayland.uwsm-wrapper.prefix} ${cmd}";
            description = ''
              The wrapper function to spawn new processes.

              This is used by hyprland to create new processes.
            '';
          };
        };
      };
    };
}
