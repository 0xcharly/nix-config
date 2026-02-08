{ pkgs, ... }:
{
  environment.defaultPackages = with pkgs; [
    errands
    gnome-calendar
  ];
  programs.dconf.enable = true;

  services.gnome = {
    evolution-data-server.enable = true;

    # To use google/nextcloud calendar
    gnome-online-accounts.enable = true;
    gnome-keyring.enable = true;
  };

  # Auto unlock default keyring on login
  security.pam.services = {
    greetd.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };
}
