{ withSystem, inputs, ... }:
{
  flake.homeModules.programs-fish =
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
      imports = [ inputs.nix-config-colorscheme.homeModules.fish ];

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
            fish_prompt = ''
              # Format template string with CWD.
              # CWD: last component only (i.e. current directory name)
              printf "%s%s %s%s%s \$%s " \
                (set_color normal; if set -q SSH_TTY; set_color $fish_color_host_remote; else set_color $fish_color_host; end) (prompt_hostname) \
                (set_color normal; set_color $fish_color_cwd) (prompt_pwd | string split /)[-1] \
                (set_color normal; if set -q SSH_TTY; set_color $fish_color_host_remote; else set_color $fish_color_host; end) \
                (set_color normal)
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
        packages = withSystem pkgs.stdenv.hostPlatform.system (
          { config, ... }:
          [
            config.packages.fishPlugins-dir-git-repository
            config.packages.fishPlugins-tmux-git-repository
          ]
        );
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages = with pkgs; {
        fishPlugins-dir-git-repository = callPackage ./fishPlugins/_dir-git-repository { };
        fishPlugins-tmux-git-repository = callPackage ./fishPlugins/_tmux-git-repository { };
      };
    };
}
