{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in rec {
  facts = builtins.fromTOML (builtins.readFile ./homelab.toml);

  builders = import ./builders.nix;
  caddy = import ./caddy.nix {inherit lib;};
  gatus = import ./gatus.nix;
  homebrew = import ./homebrew.nix;
  openssh = import ./openssh.nix {inherit facts lib;};
  uri = import ./uri.nix lib;
}
