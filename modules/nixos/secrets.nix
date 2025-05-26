{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.nix-config-secrets.nixosModules.default];

  # Enable the PC/SC (smart card) daemon for yubikey support.
  services.pcscd.enable = true;

  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubioath-flutter
  ];
}
