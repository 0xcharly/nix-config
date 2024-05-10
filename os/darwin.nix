{
  isCorpManaged,
  lib,
  pkgs,
  ...
}: {
  homebrew = {
    enable = true;
    casks =
      [
        "1password"
        "1password-cli"
        "discord"
        "firefox"
        "firefox-developer-edition"
        #"hammerspoon"
        #"monodraw"
        "raycast"
        "spotify"
      ]
      ++ (lib.optionals (!isCorpManaged) ["google-chrome"]);
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.delay = {
    home = "/Users/delay";
    shell = pkgs.fish;
  };
}
