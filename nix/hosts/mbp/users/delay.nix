{
  flake,
  inputs,
  ...
}: {
  imports = [
    inputs.nix-config-secrets.modules.home.blueprint
    inputs.nix-config-secrets.modules.home.services-atuin
    inputs.nix-config-secrets.modules.home.ssh-keys-ring-3-tier

    flake.modules.home.account-essentials
    flake.modules.home.fonts
    flake.modules.home.ghostty
    flake.modules.home.home-manager-nixos
    flake.modules.home.jujutsu-deprecated
    flake.modules.home.keychain
    flake.modules.home.secrets
    flake.modules.home.ssh-keys
  ];

  age.secretsDir = "/run/delay";

  home.stateVersion = "24.05";

  node = {
    openssh.trusted-tier.ring = 3;
    # TODO: agenix HM module on darwin create paths that require shell evaluation…
    services.atuin.enableSync = false;
  };
}
