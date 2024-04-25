{ pkgs, lib, inputs, ... }:

{
  # https://github.com/nix-community/home-manager/pull/2408
  environment.pathsToLink = [ "/share/fish" ];

  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Required for graphical interfaces (X or Wayland) to work.
  security.polkit.enable = true;

  # Since we're using fish as our shell.
  programs.fish.enable = true;

  users.users.delay = {
    isNormalUser = true;
    home = "/home/delay";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.fish;
    # Create a hashed password with `nix-shell -p mkpasswd --run "mkpasswd -m yescrypt"`
    hashedPassword = "$y$j9T$6Obep7H1BnzgcBCOdY9hO/$tyLpdkxXnRPumeqlm43Uh4UPj1UQgymEiREPSr49ZR1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4Jr8wJUXhECjbSXlGPpLFAN0Zq+eY6n4w+0ezoMxFK delay"
    ];
  };

  # Enable the unfree 1Password packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password"
    "1password-gui"
  ];

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "delay" ];
  };

  nixpkgs.overlays = [ (import ./vim.nix { inherit inputs; }) ];
}
