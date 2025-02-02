{
  # ArchLinux with Nix.
  targets.genericLinux.enable = true;

  # No graphical environment.
  modules.usrenv.compositor = "headless";

  # Not enough memory to build jujutsu from scratch.
  modules.usrenv.canBuildJujutsuUnstable = false;
}
