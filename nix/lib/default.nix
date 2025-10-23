{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in rec {
  user = builtins.fromTOML (builtins.readFile ./user.toml);
  facts = builtins.fromTOML (builtins.readFile ./homelab.toml);

  builders = import ./builders.nix;
  caddy = import ./caddy.nix {inherit lib;};
  fonts = import ./fonts.nix;
  gatus = import ./gatus.nix;
  homebrew = import ./homebrew.nix;
  openssh = import ./openssh.nix {inherit facts lib;};
  pkgs = import ./pkgs.nix inputs;
  uri = import ./uri.nix lib;
  zfs = import ./zfs.nix;
}
