{pkgs, ...}: {
  imports = [./common.nix];

  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

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

  services.fprintd.enable = true;

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Manage fonts.
  fonts = {
    fontDir.enable = true;

    packages = import ../modules/fonts {pkgs = pkgs;};
  };

  # Enable tailscale. We manually authenticate when we want with
  # "sudo tailscale up". If you don't use tailscale, you should comment
  # out or delete all of this.
  #services.tailscale.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cachix
    gnumake
    killall
    rxvt_unicode
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

  # TODO: Reenable when configuration is more stable and reinstall less frequent.
  # documentation = {
  #   enable = true;
  #   man.enable = true;
  #   dev.enable = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
