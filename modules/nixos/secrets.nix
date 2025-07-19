{
  inputs,
  lib,
  pkgs,
  ...
} @ args: let
  inherit ((lib.user.getUserConfig args).modules.usrenv) isLinuxDesktop;
in {
  imports = [inputs.nix-config-secrets.nixosModules.default];

  # Enable the PC/SC (smart card) daemon for yubikey support.
  services.pcscd.enable = isLinuxDesktop;

  environment = lib.mkIf isLinuxDesktop {
    systemPackages = with pkgs; [
      yubikey-manager
      yubioath-flutter
    ];
  };
}
