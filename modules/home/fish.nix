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
        fish_vi_key_bindings # Enable vi bindings

        # Fixes cursor shape behavior in vim mode
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

        # Convenience binds
        bind \cw backward-kill-word
      '';

      functions = {
        fish_greeting = ""; # Disable greeting message.
        fish_mode_prompt = ""; # Disable prompt vi mode reporting.
        prompt_template = ''
          if not set -q __fish_prompt_template
            # Cache the resulting template string since all of its content is
            # static, and it shells out to lolcat for highlightings.
            set -g __fish_prompt_template (
                # Reset all ANSI sequences before and after the prompt
                set_color normal
                # Create a template string starting with the hostname: "<hostname> %s $ ".
                # '%' is expanded into '%s' separately to avoid lolcat inserting escape sequences between '%' and 's'.
                printf (
                      printf "%s %% \$ " (prompt_hostname) \
                    | ${lib.getExe pkgs.lolcat} --force --seed=(printf "%d" 0x(bat /etc/machine-id |head -c8)) -p 0.5 \
                    | sed "s/%/%s/"
                ) (set_color --italics brblack; echo -n %s; set_color normal))
          end
          echo -n $__fish_prompt_template
        '';
        fish_prompt = ''
          # Format template string with CWD.
          # CWD: last component only (i.e. current directory name)
          printf (prompt_template) (prompt_pwd | string split /)[-1]
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
