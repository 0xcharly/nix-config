{
  lib,
  stdenv,
  ansifilter,
  git,
  tmux,
}:
# To make use of this derivation, use:
# ```
#   programs.fzf.enableZshIntegration = true;
#   programs.zsh.extraConfig = "source ${pkgs.open-local-repository-zsh}/share/zsh/plugins/open-local-repository/open-local-repository.plugin.zsh";
# ```
stdenv.mkDerivation {
  pname = "open-local-repository-zsh";
  version = "2024-08-22";

  src = ./.;

  strictDeps = true;
  postPatch = ''
    substituteInPlace open-local-repository.plugin.zsh \
      --replace 'command ansifilter' 'command ${lib.getExe ansifilter}' \
      --replace 'command git' 'command ${lib.getExe git}' \
      --replace 'command tmux' 'command ${lib.getExe tmux}'
  '';
  dontBuild = true;

  installPhase = ''
    install -Dm0644 open-local-repository.plugin.zsh \
      $out/share/zsh/plugins/open-local-repository/open-local-repository.plugin.zsh
  '';

  meta = with lib; {
    description = "Quick navigation to local checkouts following the `pkgs.git-get` structure";
    license = licenses.mit;
    maintainers = []; # TODO: setup lib.maintainers._0xcharly
    platforms = platforms.unix;
  };
}
