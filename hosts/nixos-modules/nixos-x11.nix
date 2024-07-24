{
  pkgs,
  globalModules,
  sharedModules,
  ...
}: {
  imports = with sharedModules; [nixos-headless];

  # Windowing environment.
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xrandrHeads = ["Virtual-1"];
    autorun = true;

    desktopManager = {
      xterm.enable = false;
      wallpaper.mode = "fill";
    };

    displayManager = {
      gdm.enable = true;

      sessionCommands = ''
        ${pkgs.xorg.xset}/bin/xset r rate 200 40
      '';
    };

    windowManager.i3.enable = true;
  };

  services.displayManager = {
    enable = true;
    defaultSession = "none+i3";
  };

  # Manage fonts.
  fonts = {
    fontDir.enable = true;

    packages = import globalModules.fonts {inherit pkgs;};
  };

  # List additional packages to install in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    xclip
  ];

  environment.etc = {
    "xdg/gtk-2.0/gtkrc".text = ''
      gtk-application-prefer-dark-theme=1
      gtk-error-bell=0
    '';
    "xdg/gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-error-bell=false
    '';
    "xdg/gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-error-bell=false
    '';
  };
}
