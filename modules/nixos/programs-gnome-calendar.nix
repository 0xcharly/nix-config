{pkgs, ...}: {
  environment.defaultPackages = with pkgs; [gnome-calendar];
  programs.dconf.enable = true;

  services.gnome = {
    evolution-data-server.enable = true;

    # To use google/nextcloud calendar
    gnome-online-accounts.enable = true;
    gnome-keyring.enable = true;
  };
}
