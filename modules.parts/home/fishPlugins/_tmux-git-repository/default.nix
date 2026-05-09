{
  lib,
  fishPlugins,
  fzf,
  git,
  tmux,
  ...
}:
fishPlugins.buildFishPlugin {
  pname = "tmux-git-repository";
  version = "2025-05-08";

  src = ./.;

  buildInput = [
    fzf
    git
    tmux
  ];

  meta = with lib; {
    description = "Quick navigation to local checkouts following the `pkgs.git-get` structure";
    license = licenses.mit;
    maintainers = [ lib.maintainers._0xcharly ];
    platforms = platforms.unix;
  };
}
