{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
rec {
  facts = builtins.fromTOML (builtins.readFile ./homelab.toml);
  inventory = builtins.fromTOML (builtins.readFile ./inventory.toml);
  user = builtins.fromTOML (builtins.readFile ./user.toml);

  builders = import ./builders.nix;
  caddy = import ./caddy.nix { inherit lib; };
  fonts = import ./fonts.nix { inherit lib; };
  gatus = import ./gatus.nix;
  homebrew = import ./homebrew.nix;
  openssh = import ./openssh.nix { inherit facts lib; };
  pkgs = import ./pkgs.nix inputs;
  uri = import ./uri.nix lib;
  zfs = import ./zfs.nix;
}
