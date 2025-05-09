# Modules used to create a NixOS image.
{
  lib,
  modulesPath,
  ...
}: {
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
  imports = [
    # Base ISO content.
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];
}
