{
  settings.compositor = "headless";

  home = rec {
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
