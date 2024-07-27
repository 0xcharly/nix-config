# This module loads the user settings into the home-manager module.
{
  config,
  host,
  ...
}: {
  # TODO: can this be done automatically?
  home-manager.users.${host.user} = {inherit (config) settings;};
}
