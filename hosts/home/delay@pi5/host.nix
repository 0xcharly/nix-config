{
  # TODO: consider switching to wayland.
  modules.usrenv.compositor = "x11";
  modules.usrenv.enableProfileFont = true;

  home = rec {
    # TODO: can this be passed in?
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
