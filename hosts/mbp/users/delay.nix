{
  flake,
  inputs,
  ...
}:
{
  imports = [
    inputs.nix-config-secrets.modules.home.blueprint
    inputs.nix-config-secrets.modules.home.services-atuin

    flake.modules.home.account-essentials
    flake.modules.home.fonts
    flake.modules.home.home-manager-nixos
    flake.modules.home.keychain
    flake.modules.home.terminals
  ];

  home.stateVersion = "24.05";

  node = {
    keychain.autoLoadTrustedKeys = false;
    # TODO: agenix HM module on darwin create paths that require shell evaluation…
    services.atuin.enableSync = false;
  };
}
