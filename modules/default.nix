{config-manager, ...}: {
  imports = with config-manager; [
    global.unfree
    global.usrenv
  ];
}
