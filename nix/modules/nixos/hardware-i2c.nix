# Used to control hardware such as monitor brightness, RGB, …
{
  hardware.i2c.enable = true;

  users.users.delay.extraGroups = ["i2c"];
}
