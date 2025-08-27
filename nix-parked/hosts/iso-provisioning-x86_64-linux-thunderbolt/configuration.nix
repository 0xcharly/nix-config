{flake, ...}: {
  imports = [
    flake.modules.iso.provisioning
  ];

  # Enable support for Thunderbolt, required to format disks.
  boot.kernelModules = ["kvm-intel" "thunderbolt"];
  networking.hostName = "skullkid";
  nixpkgs.hostPlatform = "x86_64-linux";
  services.hardware.bolt.enable = true;
}
