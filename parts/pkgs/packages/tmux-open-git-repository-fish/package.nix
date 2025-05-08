{
  lib,
  fishPlugins,
  git,
  tmux,
}:
fishPlugins.buildFishPlugin {
  pname = "tmux-open-git-repository-fish";
  version = "2025-05-08";

  src = ./.;
  postPatch = ''
    substituteInPlace functions/__tmux_open_git_repository.fish \
      --replace 'command git' 'command ${lib.getExe git}' \
      --replace 'command tmux' 'command ${lib.getExe tmux}'
  '';

  meta = with lib; {
    description = "Quick navigation to local checkouts following the `pkgs.git-get` structure";
    license = licenses.mit;
    maintainers = [lib.maintainers._0xcharly];
    platforms = platforms.unix;
  };
}
