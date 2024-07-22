{
  globalModules,
  systemModules,
  ...
}: {
  imports = [globalModules.settings systemModules.nix-index];

  settings.isHeadless = true;

  home = rec {
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
