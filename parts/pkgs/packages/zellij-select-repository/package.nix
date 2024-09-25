{
  lib,
  writers,
  ansifilter,
  coreutils,
  git,
  git-get,
  path-strip-prefix,
  ripgrep,
  zellij,
}: let
  runtimeInputs = [ansifilter coreutils git git-get path-strip-prefix ripgrep zellij];
in
  writers.writeFishBin "zellij-select-repository" (lib.concatStringsSep "\n" [
    ''
      set PATH "${lib.makeBinPath runtimeInputs}:$PATH"
    ''
    (builtins.readFile ./zellij-select-repository.fish)
  ])
