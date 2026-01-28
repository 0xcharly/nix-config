{
  flake,
  inputs,
  ...
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.fish;
in
{
  imports = [ inputs.nix-config-colorscheme.modules.home.fish ];

  programs = {
    eza.enableFishIntegration = true;

    fish = {
      enable = true;
      interactiveShellInit = ''
        fish_vi_key_bindings # Enable vi bindings.

        # Fixes cursor shape behavior in vim mode.
        set fish_cursor_default block
        set fish_cursor_insert block
        set fish_cursor_replace_one block
        set fish_cursor_replace block
        set fish_cursor_external block
        set fish_cursor_visual block

        # TODO: figure out where those are defined…
        bind --erase ctrl-t
        bind --erase -M insert ctrl-t
        bind --erase alt-c
        bind --erase -M insert alt-c
      '';

      functions = {
        fish_greeting = ""; # Disable greeting message.
        fish_mode_prompt = ""; # Disable prompt vi mode reporting.
        fish_prompt = ''
          set -l last_status $status

          set_color brblack
          printf (prompt_hostname)
          set_color -i green
          printf " %s " (prompt_pwd | string split /)[-1]
          set_color normal
          if test $last_status -ne 0
              set_color red
          else
              set_color brblack
          end
          printf "\$ "
          set_color normal
        '';
      };
      shellAliases.nixsh = "nix-shell --run ${lib.getExe cfg.package}";
    };

    tmux.shell = lib.getExe cfg.package;
  };

  home = {
    sessionVariables.SHELL = lib.getExe cfg.package;
    shell = {
      enableBashIntegration = false;
      enableFishIntegration = false;
    };
    packages = [ flake.packages.${pkgs.stdenv.hostPlatform.system}.tmux-open-git-repository-fish ];
  };
}
