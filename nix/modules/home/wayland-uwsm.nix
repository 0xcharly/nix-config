{
  config,
  lib,
  pkgs,
  ...
}: {
  options.node.wayland = with lib; {
    uwsm-wrapper = {
      package = mkPackageOption pkgs "uwsm" {
        extraDescription = ''
          The uwsm wrapper script to use to spawn new processes.

          Defaults to `uwsm`.

          Consider `app2unit` as a faster alternative to `uwsm` (shell
          implementation over Python).
        '';
      };

      prefix = mkOption {
        type = types.str;
        default = "${lib.getExe config.node.wayland.uwsm-wrapper.package} app --";
        description = ''
          The prefix command to spawn new processes.

          This is used by walker to create new processes.
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
}
