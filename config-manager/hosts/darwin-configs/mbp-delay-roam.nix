{globalModules, ...}: {
  imports = [globalModules.settings];

  settings.isCorpManaged = true;
  settings.migrateHomebrew = true;
}
