{
  globalModules,
  sharedModules,
  ...
}: {
  imports = [globalModules.settings sharedModules.nix-index];

  settings.isHeadless = true;

  home = rec {
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
