{config-manager, ...}: {
  imports = with config-manager; [
    global.settings
    global.unfree
  ];
}
