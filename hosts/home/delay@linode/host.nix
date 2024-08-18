{
  # No graphical environment.
  modules.usrenv.compositor = "headless";

  home = rec {
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
