{
  flake,
  inputs,
  hostName,
  ...
}: {
  class = "nixos";

  value = inputs.nixos-raspberrypi.lib.nixosSystemFull {
    specialArgs = {
      inherit inputs;
      inherit (inputs) nixos-raspberrypi;
    };
    system = "aarch64-linux";
    modules = [
      {
        # Hardware specific configuration, see section below for a more complete
        # list of modules
        imports = with inputs.nixos-raspberrypi.nixosModules; [
          sd-image

          raspberry-pi-5.base
          raspberry-pi-5.page-size-16k
          raspberry-pi-5.display-vc4
          raspberry-pi-5.bluetooth

          # Add necessary overlays with kernel, firmware, vendor packages.
          # inputs.nixos-raspberrypi.lib.inject-overlays

          # Binary cache with prebuilt packages for the currently locked
          # `nixpkgs`, see `devshells/nix-build-to-cachix.nix` for a list.
          trusted-nix-caches

          # All RPi and RPi-optimised packages to be available in `pkgs.rpi`.
          nixpkgs-rpi
        ];

        # https://github.com/nvmd/nixos-raspberrypi?tab=readme-ov-file#provides-bootloader-infrastructure
        boot.loader.raspberryPi.bootloader = "kernel";
      }

      ./configtxt.nix
      (import ./configuration.nix {inherit flake inputs hostName;})
    ];
  };
}
