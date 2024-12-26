{inputs, ...}: {
  imports = [inputs.disko.nixosModules.disko];

  disko.devices.disk = {
    sda = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "btrfs";
        subvolumes = {
          "/" = {
            mountpoint = "/";
            mountOptions = ["compress=zstd"];
          };
          "/nix" = {
            mountpoint = "/nix";
            mountOptions = ["compress=zstd" "noatime"];
          };
        };
      };
    };
    sdb = {
      device = "/dev/sdb";
      type = "disk";
      content = {
        type = "swap";
        randomEncryption = true;
        resumeDevice = true;
      };
    };
  };
}
