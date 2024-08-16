{lib, ...}: let
  inherit (builtins) baseNameOf elem filter map toString;
  inherit (lib.filesystem) listFilesRecursive;

  # `mkModuleTree` is used to recursively import all `module.nix` file in a
  # given directory, assuming the given directory to be the module root, where
  # rest of the modules are to be imported.
  mkModuleTree = {
    root,
    ignoredPaths ? [],
  }:
    filter (path: (baseNameOf path) == "module.nix") (
      map toString (
        # List all files in the given path, and filter out paths that are in
        # the ignoredPaths list
        filter (path: !elem path ignoredPaths) (listFilesRecursive root)
      )
    );
in {
  inherit mkModuleTree;
}
