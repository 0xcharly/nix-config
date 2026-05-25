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

      builders = import ./_builders.nix;
      caddy = import ./_caddy.nix { inherit uri; };
      fonts = import ./_fonts.nix { inherit lib; };
      gatus = import ./_gatus.nix { inherit lib; };
      homebrew = import ./_homebrew.nix;
      openssh = import ./_openssh.nix { inherit facts lib uri; };
      uri = import ./_uri.nix lib;
      zfs = import ./_zfs.nix;
    };
}
