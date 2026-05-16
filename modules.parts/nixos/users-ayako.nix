{ self, ... }:
{
  flake.nixosModules.users-ayako =
    { pkgs, ... }:
    {
      imports = [ self.nixosModules.users-common ];

      users = {
        # Creates the group `ayako`
        groups.ayako = { };

        # Creates the user `ayako`
        users.ayako = {
          isNormalUser = true;
          home = "/home/ayako";
          group = "ayako";
          extraGroups = [ "users" ];
          shell = pkgs.bash;
        };
      };
    };
}
