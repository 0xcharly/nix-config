{
  nix.settings = rec {
    allowed-users = ["delay"];
    trusted-users = allowed-users;

    # Enable flakes.
    experimental-features = "nix-command flakes";
    accept-flake-config = true;
  };

  nix.gc.automatic = true; # Run garbage collection periodically. Default is weekly.
}
