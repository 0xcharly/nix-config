{lib}: {
  mkConfig = config:
    lib.generators.toKeyValue {
      listsAsDuplicateKeys = true;
    }
    config;
}
