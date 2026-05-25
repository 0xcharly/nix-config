{
  flake.homeModules.services-acpi =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        acpi # Battery
      ];
    };
}
