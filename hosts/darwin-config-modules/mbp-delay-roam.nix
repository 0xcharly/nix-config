{utilsSharedModules, ...}: {
  imports = [utilsSharedModules.settings];

  settings.isCorpManaged = true;
  settings.migrateHomebrew = true;
}
