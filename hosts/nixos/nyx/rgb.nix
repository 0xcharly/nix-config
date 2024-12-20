{
  pkgs,
  lib,
  ...
}: let
  no-rgb = pkgs.writeShellApplication {
    name = "no-rgb";
    runtimeInputs = [pkgs.openrgb];
    text = ''
      NUM_DEVICES=$(openrgb --noautoconnect --list-devices | grep -cE '^[0-9]+: ')

      for i in $(seq 0 $((NUM_DEVICES - 1))); do
        openrgb --noautoconnect --device "$i" --mode off
      done
    '';
  };
in {
  # NOTE: RAM support was most likely added in but will be available as part of 1.0:
  # - https://gitlab.com/CalcProgrammer1/OpenRGB/-/merge_requests/2435
  services.udev.packages = [pkgs.openrgb];
  boot.kernelModules = ["i2c-dev" "i2c-piix4"];
  boot.kernelParams = ["acpi_enforce_resources=lax"];
  hardware.i2c.enable = true;

  systemd.services.no-rgb = {
    description = "Disable all RGB";
    serviceConfig = {
      ExecStart = lib.getExe no-rgb;
      Type = "oneshot";
    };
    wantedBy = ["multi-user.target"];
    restartIfChanged = true;
  };
}
