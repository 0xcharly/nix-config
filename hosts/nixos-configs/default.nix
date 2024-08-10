{config-manager, ...}: {
  imports = with config-manager; [global.home-manager-settings-inject];
}
