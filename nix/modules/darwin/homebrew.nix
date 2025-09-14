{
  config,
  inputs,
  ...
}: {
  # Nix-managed homebrew.
  imports = [inputs.nix-homebrew.darwinModules.nix-homebrew];

  nix-homebrew = {
    enable = true; # Install Homebrew under the default prefix.
    user = config.system.primaryUser; # User owning the Homebrew prefix.
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
    };
    casks = [
      "1password" # Password manager.
      "bitwarden-cli" # Password management automation.
      "ghostty" # Terminal.
      "raycast" # Mandatory Spotlight alternative.
    ];
  };
}
