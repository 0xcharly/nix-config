# Used to control hardware such as monitor brightness, RGB, …
{
  flake.nixosModules.hardware-i2c = {
    hardware.i2c.enable = true;
    users.users.delay.extraGroups = [ "i2c" ];
  };
}
