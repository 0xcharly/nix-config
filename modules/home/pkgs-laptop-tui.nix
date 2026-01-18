{ pkgs, ... }:
{
  home.packages = with pkgs; [
    acpi # Battery.
  ];
}
