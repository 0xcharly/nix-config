{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [inputs.nix-config-secrets.nixosModules.default];
}
// (lib.mkIf config.modules.stdenv.isNixOS {
  # Enable the PC/SC (smart card) daemon for yubikey support.
  services.pcscd.enable = true;

  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubioath-flutter
  ];
})
