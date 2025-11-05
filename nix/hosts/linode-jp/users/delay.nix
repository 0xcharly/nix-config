{
  # Blueprint parameters.
  flake,
  inputs,
  # Module parameters.
  ...
}: {
  imports = [
    inputs.nix-config-secrets.modules.home.blueprint
    inputs.nix-config-secrets.modules.home.services-atuin
    inputs.nix-config-secrets.modules.home.ssh-keys-ring-3-tier

    flake.modules.home.account-essentials
    flake.modules.home.home-manager-nixos
    flake.modules.home.jujutsu-deprecated
    flake.modules.home.keychain
    flake.modules.home.secrets
    flake.modules.home.ssh-keys
  ];

  home.stateVersion = "25.05";

  node = {
    openssh.trusted-tier.ring = 3;
    services.atuin.enableSync = true;
  };
}
