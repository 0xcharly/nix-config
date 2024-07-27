{
  nixpkgs.config.allowUnfreePredicate = _: false;
  # builtins.elem (lib.getName pkg) (lib.optionals (!config.settings.isCorpManaged) [
  #   "copilot.vim"
  # ]);
}
