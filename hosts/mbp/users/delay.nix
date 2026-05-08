{
  flake,
  inputs,
  ...
}:
{
  imports = [
    inputs.nix-config-secrets.homeModules.default
    inputs.nix-config-secrets.homeModules.services-atuin

    flake.homeModules.account-essentials
    flake.homeModules.fonts
    flake.homeModules.home-manager-nixos
    flake.homeModules.keychain
    flake.homeModules.nixpkgs-unstable
    flake.homeModules.terminals
  ];

  home.stateVersion = "24.05";

  node = {
    keychain.autoLoadTrustedKeys = false;
    # TODO: agenix HM module on darwin create paths that require shell evaluation…
    services.atuin.enableSync = false;
  };
}
