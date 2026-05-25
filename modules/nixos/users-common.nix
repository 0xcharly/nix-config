{
  flake.nixosModules.users-common = {
    # TODO: fold into `access-directory.nix` once migration is completed
    users.mutableUsers = false;
  };
}
