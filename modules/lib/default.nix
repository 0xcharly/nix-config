{ inputs, ... }:
{
  flake.lib =
    let
      inherit (inputs.nixpkgs) lib;
    in
    rec {
      facts = fromTOML (builtins.readFile ./homelab.toml);
      inventory = fromTOML (builtins.readFile ./inventory.toml);

      builders = import ./internal/builders.nix;
      caddy = import ./internal/caddy.nix { inherit uri; };
      gatus = import ./internal/gatus.nix { inherit lib; };
      homebrew = import ./internal/homebrew.nix;
      openssh = import ./internal/openssh.nix { inherit facts lib uri; };
      theme = import ./internal/theme.nix {
        inherit lib;
        fonts = fromTOML (builtins.readFile ./fonts.toml);
      };
      uri = import ./internal/uri.nix lib;
      zfs = import ./internal/zfs.nix;
    };
}
