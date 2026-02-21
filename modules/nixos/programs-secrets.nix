{ pkgs, ... }:
{
  # Enable the PC/SC (smart card) daemon for yubikey support.
  services.pcscd.enable = true;

  environment.systemPackages = with pkgs; [
    bitwarden-desktop
    yubikey-manager
    yubioath-flutter
  ];
}
