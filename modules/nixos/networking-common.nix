{
  networking = {
    # The global useDHCP flag is deprecated, therefore explicitly set to false
    # here. Per-interface useDHCP will be mandatory in the future, so this config
    # replicates the default behaviour.
    useDHCP = false;

    # NetworkManager is controlled using either nmcli or nmtui.
    networkmanager.enable = true;
  };

  # All users that should have permission to change network settings must belong
  # to the networkmanager group:
  users.users.delay.extraGroups = ["networkmanager"];
}
