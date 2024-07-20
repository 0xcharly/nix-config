{
  globalModules,
  hmModules,
  ...
}: {
  imports =
    (with hmModules; [delay nix-index])
    ++ (with globalModules; [settings]);

  settings.isCorpManaged = true;
  settings.isHeadless = true;

  home = rec {
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
