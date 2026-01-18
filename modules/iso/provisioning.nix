# Modules used to create a NixOS image.
{
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    # Base ISO content.
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];

  networking.useDHCP = lib.mkForce true;

  # Setup SSH to disable password authentication.
  services.openssh = {
    enable = true;
    openFirewall = true;

    settings = {
      PermitRootLogin = lib.mkDefault "yes";
      PasswordAuthentication = lib.mkDefault false;
      KbdInteractiveAuthentication = lib.mkDefault false;
    };
  };

  # Setup root to accept our SSH key.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOthTpNSA6sSEV6398UlRWm7H7O3S6cq/mkOgqKJ7PF3 provisioning"
  ];

  environment.systemPackages = with pkgs; [
    fish
    git

    duf # Modern `df` alternative.
    nvim # Our own package installed by overlay.
    tree # List the content of directories in a tree-like format.
    yazi # File explorer that supports Kitty image protocol.
  ];
}
