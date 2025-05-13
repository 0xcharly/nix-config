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
    # Create a hashed password with `nix-shell -p mkpasswd --run "mkpasswd -m yescrypt"`
    hashedPassword = "$y$j9T$TrN/LFDpdc5kkHZc6bkyV1$b4TqAfjBY2xuwmAUHVbco.cyI43JzOjs1dXt5ey3c.3";
  };
}
