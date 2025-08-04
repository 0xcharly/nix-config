{
  inputs,
  lib,
  ...
} @ args: let
  listFilesWithSuffixRecursive = suffix: dir:
    lib.filter
    (p: lib.hasSuffix suffix p && !(lib.hasPrefix "_" (builtins.baseNameOf p)))
    (lib.filesystem.listFilesRecursive dir);

  listModulesRecursive = listFilesWithSuffixRecursive ".nix";

  listModulesRecursive' = dirname:
    lib.filter (path: path != dirname + "/default.nix") (listModulesRecursive dirname);
in {
  fn =
    {
      inherit listFilesWithSuffixRecursive listModulesRecursive listModulesRecursive';
    }
    // lib.foldr (path: acc: acc // (import path args)) {} (listModulesRecursive' ./fn);

  user = lib.foldr (path: acc: acc // (import path args)) {} (listModulesRecursive' ./user);

  # Also inject Home-Manager's lib which seems to be required for standalone hosts.
  # TODO: is this OK?
  inherit (inputs.home-manager.lib) hm;
}
