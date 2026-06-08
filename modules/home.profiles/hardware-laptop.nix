{ self, ... }:
{
  flake.homeModules.profile-hardware-laptop = {
    imports = with self.homeModules; [ services-acpi ];

    config.node.wayland = {
      idle = {
        suspend.timeout = 15 * 60; # 15 minutes
        hibernate = {
          enable = true;
          timeout = 30 * 60; # 30 minutes
        };
      };

      arcshell.modules.power = true;
    };
  };
}
