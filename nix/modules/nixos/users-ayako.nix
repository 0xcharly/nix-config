{flake, ...}: {pkgs, ...}: {
  imports = [flake.modules.nixos.users-common];

  users = {
    # Creates the group `ayako`.
    groups.ayako = {};

    # Creates the user `ayako`.
    users.ayako = {
      isNormalUser = true;
      home = "/home/ayako";
      group = "ayako";
      shell = pkgs.bash;
    };
  };
}
