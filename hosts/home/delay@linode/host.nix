{lib, ...}: {
  # ArchLinux with Nix.
  targets.genericLinux.enable = true;

  # No graphical environment.
  modules.usrenv.compositor = "headless";

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) ["copilot.vim"];
}
