{
  # ArchLinux with Nix.
  targets.genericLinux.enable = true;

  # No graphical environment.
  modules.usrenv.compositor = "headless";
}
