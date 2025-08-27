{flake, ...}: {
  imports = [
    flake.modules.iso.provisioning
  ];

  boot.kernelParams = ["console=ttyS0"]; # For LISH compatibility.
  networking.hostName = "linode";
  nixpkgs.hostPlatform = "x86_64-linux";
}
