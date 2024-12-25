{inputs, ...}: {
  imports = [inputs.disko.nixosModules.disko];

  disko.devices.disk = {
    sda = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
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
