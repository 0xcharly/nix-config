{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.modules.system.roles.nas.enable {
  # Creates the group `ayako`.
  users.groups.ayako = {};

  # Creates the user `ayako`.
  users.users.ayako = {
    isNormalUser = true;
    home = "/home/ayako";
    group = "ayako";
    shell = pkgs.bash;
  };
}
