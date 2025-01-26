{
  imports = [];

  # Use a desktop environment.
  # TODO: consider switching to wayland.
  modules.usrenv.compositor = "x11";

  # Setup qemu so we can run x86_64 binaries.
  boot.binfmt.emulatedSystems = ["x86_64-linux"];

  # Don't require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  networking.hostName = "rpi4";

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnsupportedSystem = true;
}
