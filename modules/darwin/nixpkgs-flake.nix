# https://github.com/nix-darwin/nix-darwin/blob/8df64f819698c1fee0c2969696f54a843b2231e8/modules/nix/nixpkgs-flake.nix
{
  # Keep this consistent instead of automagically swapping nixpkgs for
  # nixpkgs-darwin on nix-darwin.
  nixpkgs.flake = {
    setFlakeRegistry = false;
    setNixPath = false;
  };
}
