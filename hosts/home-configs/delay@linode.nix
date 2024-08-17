{
  # No graphical environment.
  usrenv.compositor = "headless";

  home = rec {
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
