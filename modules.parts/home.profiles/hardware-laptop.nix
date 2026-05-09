{ self, ... }:
{
  flake.homeModules.profile-hardware-laptop = {
    imports = with self.homeModules; [
      services-acpi
    ];
  };
}
