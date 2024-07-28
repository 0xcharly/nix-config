{
  config,
  lib,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) (lib.optionals (!config.settings.isCorpManaged) [
      "copilot.vim"
    ]);
}
