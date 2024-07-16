{
  hmSharedModules,
  lib,
  ...
}: {
  imports = lib.attrValues {inherit (hmSharedModules) delay nix-index;};

  home = rec {
    username = "delay";
    homeDirectory = "/home/${username}";
  };
}
