{ inputs, ... }:
{
  flake.lib =
    let
      inherit (inputs.nixpkgs) lib;
    in
    rec {
      facts = fromTOML (builtins.readFile ./homelab.toml);
      inventory = fromTOML (builtins.readFile ./inventory.toml);
      user = fromTOML (builtins.readFile ./user.toml);

      builders = import ./internal/builders.nix;
      caddy = import ./internal/caddy.nix { inherit uri; };
      colors = import ./internal/colors { inherit lib; };
      fonts = import ./internal/fonts.nix { inherit lib; };
      gatus = import ./internal/gatus.nix { inherit lib; };
      homebrew = import ./internal/homebrew.nix;
      openssh = import ./internal/openssh.nix { inherit facts lib uri; };
      uri = import ./internal/uri.nix lib;
      zfs = import ./internal/zfs.nix;
    };
}
