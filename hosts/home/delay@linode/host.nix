{
  # No graphical environment.
  modules.usrenv.compositor = "headless";

  home = rec {
    # TODO: can this be passed in?
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
