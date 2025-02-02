{
  imports = [];

  # No desktop environment.
  modules.usrenv.compositor = "headless";

  # Setup qemu so we can run x86_64 binaries.
  boot.binfmt.emulatedSystems = ["x86_64-linux"];

  # Don't require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  networking.hostName = "rpi5";

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnsupportedSystem = true;
}
