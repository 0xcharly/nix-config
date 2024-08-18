# This file is normally automatically generated. Since we build a VM
# and have full control over that hardware I can hardcode this into my
# repository.
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = ["umask=0077"];
  };

  swapDevices = [{device = "/dev/disk/by-label/swap";}];
}
