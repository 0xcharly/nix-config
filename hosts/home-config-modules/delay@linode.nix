{
  hmSharedModules,
  utilsSharedModules,
  ...
}: {
  imports =
    (with hmSharedModules; [delay nix-index])
    ++ (with utilsSharedModules; [settings]);

  settings.isHeadless = true;

  home = rec {
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
