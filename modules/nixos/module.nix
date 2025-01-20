{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.catppuccin.nixosModules.catppuccin
    inputs.home-manager.nixosModules.home-manager

    ./fonts.nix
    ./nix-client-config.nix
    ./nix-index.nix
    ./nixos-compositor-common.nix
    ./nixos-wayland.nix
    ./nixos-x11.nix
    ./terminfo.nix
    ./user-delay.nix
  ];

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Select internationalization properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
      "C.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "fr_FR.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
    ];

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
  catppuccin.tty.enable = true;

  # Enable tailscale. We manually authenticate when we want with
  # "sudo tailscale up". If you don't use tailscale, you should comment
  # out or delete all of this.
  #services.tailscale.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gnumake
    killall
    rxvt-unicode-unwrapped
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = lib.mkDefault true;
      PermitRootLogin = "no";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion.
  system.stateVersion = lib.mkDefault "24.05"; # Did you read the comment?
}
