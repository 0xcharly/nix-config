{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkIf config.modules.system.roles.nixos.intelThunderbolt {
  boot.kernelModules = ["thunderbolt"];

  services.hardware.bolt.enable = true;

  systemd.services.zfs-mount-tank = {
    # Wait for the bay to be online before mounting the devices.
    after = ["enroll-thunderbolt-devices.service"];
    requires = ["enroll-thunderbolt-devices.service"];
  };

  # Automatically enroll Thunderbolt bay on boot.
  systemd.services.enroll-thunderbolt-devices = {
    description = "Enroll the Thunderbolt devices";

    # This is required to mount the ZFS pool.
    # Wait for the agenix service to be running / complete before mounting the ZFS pool.
    after = ["bolt.service"];
    requires = ["bolt.service"];
    wantedBy = ["zfs-mount-tank.service"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = let
        enroll-thunderbolt-devices = pkgs.writeShellApplication {
          name = "enroll-thunderbolt-devices";
          runtimeInputs = with pkgs; [bolt];
          text = ''
            set -euo pipefail

            # OWC Thunderbay 4 Mini. Fails if already enrolled.
            boltctl enroll --chain d2030000-0090-8518-a3c6-b11cd472f122 || exit 0

            sleep 30 # Wait for the drives to be detected. This is only needed on the first boot.
          '';
        };
      in
        lib.getExe enroll-thunderbolt-devices;
    };
  };
}
