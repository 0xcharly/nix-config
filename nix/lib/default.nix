{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in rec {
  facts = builtins.fromTOML (builtins.readFile ./homelab.toml);

  builders = import ./builders.nix;
  homebrew = import ./homebrew.nix;
  monitoring = import ./monitoring.nix;
  openssh = import ./openssh.nix {inherit facts lib;};
  uri = import ./uri.nix lib;
}
