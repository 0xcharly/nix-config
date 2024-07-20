{globalModules, ...}: {
  imports = [globalModules.settings];

  settings.isCorpManaged = true;
}
