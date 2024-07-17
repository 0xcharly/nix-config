{hmSharedModules, ...}: {
  imports = with hmSharedModules; [delay nix-index];

  home = rec {
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
