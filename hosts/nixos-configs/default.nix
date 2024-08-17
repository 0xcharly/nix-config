{config-manager, ...}: {
  imports = with config-manager; [global.home-manager-usrenv-inject];
}
