{
  flake.nixosModules.users-root =
    { config, ... }:
    {
      # TODO: fold into `access-directory.nix` once migration is completed
      users = {
        mutableUsers = false;
        users.root.hashedPasswordFile = config.age.secrets."passwd/root".path;
      };
    };
}
