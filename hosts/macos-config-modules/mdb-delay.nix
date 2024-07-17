{utilsSharedModules, ...}: {
  imports = [utilsSharedModules.settings];

  settings.isCorpManaged = true;
}
