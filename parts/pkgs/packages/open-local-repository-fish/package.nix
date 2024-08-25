{
  lib,
  fishPlugins,
  ansifilter,
  git,
  path-strip-prefix,
  ripgrep,
  tmux,
}:
fishPlugins.buildFishPlugin {
  pname = "open-local-repository";
  version = "2024-08-23";

  src = ./.;
  postPatch = ''
    substituteInPlace functions/__open_local_repository.fish \
      --replace 'command ansifilter' 'command ${lib.getExe ansifilter}' \
      --replace 'command git' 'command ${lib.getExe git}' \
      --replace 'command path-strip-prefix' 'command ${lib.getExe path-strip-prefix}' \
      --replace 'command rg' 'command ${lib.getExe ripgrep}' \
      --replace 'command tmux' 'command ${lib.getExe tmux}'
  '';

  meta = with lib; {
    description = "Quick navigation to local checkouts following the `pkgs.git-get` structure";
    license = licenses.mit;
    maintainers = []; # TODO: setup lib.maintainers._0xcharly
    platforms = platforms.unix;
  };
}
