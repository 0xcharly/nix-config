{
  globalModules,
  hmModules,
  ...
}: {
  imports =
    (with hmModules; [delay nix-index])
    ++ (with globalModules; [settings]);

  settings.isHeadless = true;

  home = rec {
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
