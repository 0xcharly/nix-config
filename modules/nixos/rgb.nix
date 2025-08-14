{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.node.hardware.rgb;
in {
  # This is currently doing nothing since the 24.11 version of OpenRGB (<1.0)
  # does not support the host's hardware, and the CPU cooler's RGB is already
  # disabled in BIOS.
  # TODO(25.11): consider re-enabling this service in 25.11 or later when
  # OpenRGB is supporting more hardware.

  options.node.hardware.rgb.disable = lib.mkEnableOption ''
    Whether to disable all hardware RGB lightning.
  '';

  config = lib.mkIf (false && cfg.disable) {
    # NOTE: RAM support was most likely added in but will be available as part of 1.0:
    # - https://gitlab.com/CalcProgrammer1/OpenRGB/-/merge_requests/2435
    services.udev.packages = with pkgs; [openrgb];
    boot = {
      kernelModules = ["i2c-dev" "i2c-piix4"];
      kernelParams = ["acpi_enforce_resources=lax"];
    };
    hardware.i2c.enable = true;

    systemd.services.no-rgb = {
      description = "Disable all RGB";
      serviceConfig = {
        ExecStart = let
          no-rgb = pkgs.writeShellApplication {
            name = "no-rgb";
            runtimeInputs = with pkgs; [openrgb];
            text = ''
              NUM_DEVICES=$(openrgb --noautoconnect --list-devices | grep -cE '^[0-9]+: ')

              for i in $(seq 0 $((NUM_DEVICES - 1))); do
                openrgb --noautoconnect --device "$i" --mode off
              done
            '';
          };
        in
          lib.getExe no-rgb;
        Type = "oneshot";
      };
      wantedBy = ["multi-user.target"];
      restartIfChanged = true;
    };
  };
}
