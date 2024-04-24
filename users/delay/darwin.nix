{ inputs, pkgs, ... }:

{
  nixpkgs.overlays = [(import ./vim.nix { inherit inputs; })];

  homebrew = {
    enable = true;
    casks  = [
      "1password"
      "1password-cli"
      "cleanshot"
      "discord"
      "firefox"
      "firefox-developer-edition"
      "google-chrome"
      "hammerspoon"
      "monodraw"
      "raycast"
      "spotify"
    ];
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.delay = {
    home = "/Users/delay";
    shell = pkgs.fish;
  };
}
