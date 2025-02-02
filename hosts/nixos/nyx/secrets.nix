{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nix-config-secrets.nixosModules.agenix
    inputs.nix-config-secrets.nixosModules.sops
  ];

  # Enable the PC/SC (smart card) daemon for yubikey support.
  services.pcscd.enable = true;

  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-manager-qt
  ];
}
