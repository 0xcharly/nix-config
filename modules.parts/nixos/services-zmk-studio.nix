# Used to enable ZMK Studio
{
  flake.nixosModules.services-zmk-studio = {
    users.users.delay.extraGroups = [
      "uucp"
      "dialout"
    ];
  };
}
