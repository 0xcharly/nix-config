{
  globalModules,
  hmModules,
  ...
}: {
  imports = [hmModules.nix-index globalModules.settings];

  settings.isCorpManaged = true;
  settings.isHeadless = true;

  home = rec {
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
