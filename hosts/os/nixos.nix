{pkgs, ...}: {
  # https://github.com/nix-community/home-manager/pull/2408
  environment.pathsToLink = ["/share/fish"];

  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Required for graphical interfaces (X or Wayland) to work.
  security.polkit.enable = true;

  # Since we're using ZSH as our shell.
  programs.zsh.enable = true;
  programs.fish.enable = true; # TODO: remove once fully migrated to ZSH.

  users.users.delay = {
    isNormalUser = true;
    home = "/home/delay";
    extraGroups = ["docker" "wheel"];
    shell = pkgs.zsh;
    # Create a hashed password with `nix-shell -p mkpasswd --run "mkpasswd -m yescrypt"`
    hashedPassword = "$y$j9T$6Obep7H1BnzgcBCOdY9hO/$tyLpdkxXnRPumeqlm43Uh4UPj1UQgymEiREPSr49ZR1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB/bLz52u0dTFYTfJelVbXbU+VK7H4OXgre/8Mgx1+cq"
    ];
  };
}
