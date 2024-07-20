{
  globalModules,
  hmModules,
  ...
}: {
  imports = [hmModules.nix-index globalModules.settings];

  settings.isHeadless = true;

  home = rec {
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
