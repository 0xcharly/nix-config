{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.modules.system.roles.nas.enable {
  users.users.ayako = {
    isNormalUser = true;
    home = "/home/ayako";
    shell = pkgs.bash;
    hashedPassword = "*"; # Disable password login.
  };
}
