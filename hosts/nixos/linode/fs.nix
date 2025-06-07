{inputs, ...}: {
  imports = [inputs.disko.nixosModules.disko];

  disko.devices.disk.SYSTEM = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # BIOS boot partition (for GRUB in BIOS mode)
        };
        nixos = {
          label = "nixos";
          size = "100%";
          content = {
            type = "btrfs";
            subvolumes = {
              "NIXOS" = {};
              "NIXOS/rootfs" = {
                mountpoint = "/";
                mountOptions = ["compress=zstd"];
              };
              "NIXOS/nix" = {
                mountpoint = "/nix";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "NIXOS/swap" = {
                mountpoint = "/.swapvol";
                swap.swapfile.size = "2G";
              };
            };
          };
        };
      };
    };
  };
}
