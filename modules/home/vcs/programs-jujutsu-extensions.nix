{
  flake.homeModules.programs-jujutsu-extensions =
    { pkgs, ... }:
    let
      # `jj sync [--all]`: fetch, rebase local work onto the updated main,
      # then start a fresh working-copy commit on top of it. Rebase runs
      # before `jj new` while "the current branch" is still reachable from
      # @; on a rebase conflict `set -e` aborts, leaving @ on the
      # conflicted stack. jj aliases cannot chain commands, hence the
      # `util exec` escape hatch.
      jj-sync = pkgs.writeShellScript "jj-sync" ''
        set -euo pipefail

        all=false
        for arg in "$@"; do
          case "$arg" in
          --all) all=true ;;
          *)
            echo "usage: jj sync [--all]" >&2
            exit 2
            ;;
          esac
        done

        jj git fetch
        if "$all"; then
          # Rebase every local stack (all mutable commits) onto main.
          jj rebase -d main -s 'all:roots(mutable())'
        else
          # Rebase only the branch containing the working copy.
          jj rebase -d main -b '@'
        fi
        jj new main
      '';
    in
    {
      programs.jujutsu.settings.aliases.sync = [
        "util"
        "exec"
        "--"
        "${jj-sync}"
      ];
    };
}
