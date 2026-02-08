# https://nixos.wiki/wiki/Laptop
{
  powerManagement = {
    enable = true;
    powertop.enable = true; # Auto-tune on start.
  };
}
