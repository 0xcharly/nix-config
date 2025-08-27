{
  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this config
  # replicates the default behaviour.
  networking.useDHCP = false;
}
