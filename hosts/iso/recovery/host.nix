{pkgs, ...}: {
  # This can be updated with each release since this is the netboot image.
  system.stateVersion = "24.11";

  # Configure nixpkgs.
  nixpkgs.config.allowUnfree = true;

  # Setup SSH to disable password authentication.
  services.openssh = {
    enable = true;
    openFirewall = true;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Setup root to accept our SSH key.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOthTpNSA6sSEV6398UlRWm7H7O3S6cq/mkOgqKJ7PF3 recovery-iso"
  ];

  environment.systemPackages = with pkgs; [
    fish
    git

    duf # Modern `df` alternative.
    tree # List the content of directories in a tree-like format.
    yazi # File explorer that supports Kitty image protocol.
    nvim # Our own package installed by overlay.
  ];
}
