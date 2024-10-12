{
  lib,
  writers,
  git,
  zellij,
}: let
  runtimeInputs = [git zellij];
in
  writers.writeFishBin "zellij-select-repository" (lib.concatStringsSep "\n" [
    ''
      set PATH "${lib.makeBinPath runtimeInputs}:$PATH"
    ''
    (builtins.readFile ./zellij-select-repository.fish)
  ])
