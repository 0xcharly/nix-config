{ inputs, ... }:
{
  flake.darwinModules.homebrew =
    { config, ... }:
    {
      # Nix-managed homebrew
      imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

      nix-homebrew = {
        enable = true; # Install Homebrew under the default prefix
        user = config.system.primaryUser; # User owning the Homebrew prefix
      };

      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;
          cleanup = "zap";
        };
        global = {
          brewfile = true;
          autoUpdate = false;
        };
        masApps = {
          Amphetamine = 937984704;
          ColorSlurp = 1287239339;
          Xcode = 497799835;
        };
        casks = [
          "1password" # Password manager
          "bitwarden" # Personal password management
          "firefox@developer-edition" # Firefox, for isolates
          "google-chrome" # When there's no alternatives
          "kitty" # Terminal
          "proton-pass" # Personal password management
          "protonvpn" # Private network
          "tailscale-app" # Personal VPN network
          "transmission"
          "ungoogled-chromium"
          "vlc" # Media player
        ];
      };
    };
}
