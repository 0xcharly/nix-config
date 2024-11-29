{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (config.modules.usrenv) switcherApp;

  homeDirectory = config.users.users.delay.home;
  codeDirectory = homeDirectory + "/code";
in {
  home.packages =
    lib.optionals (switcherApp == "zellij") [
      # TODO: remove once injected properly.
      pkgs.zellij-select-repository
    ]
    ++ lib.optionals (switcherApp == "tmux") [
      pkgs.open-local-repository-fish
    ];

  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    escapeTime = 0;
    historyLimit = 10000;
    keyMode = "vi";
    mouse = true;
    secureSocket = true;
    sensibleOnTop = false;
    # Do not force catppuccin theme here since it sets the "default" value to a
    # solid color, which doesn't play well with translucent terminal background.
    catppuccin.enable = false;

    extraConfig = builtins.readFile ./tmux.conf;
  };

  programs.zellij = {
    enable = true;
    catppuccin.enable = true;
    settings = {
      default_mode = "locked";
      scrollback_editor = lib.getExe pkgs.nvim;
      ui.pane_frames = {
        rounded_corners = true;
        hide_session_name = true;
      };
      plugins = {
        pathfinder._props = {
          location = "file:${lib.getExe pkgs.zellij-switch-repository}";
        };
      };

      keybinds = let
        cmd = cmd: {"${cmd}" = {};};
        cmdAndSwitchToMode = cmd: mode: {
          "${cmd}" = {};
          "SwitchToMode \"${mode}\"" = {};
        };
        cmdAndLock = cmd: cmdAndSwitchToMode cmd "locked";
      in {
        _props.clear-defaults = true;

        locked = {
          "bind \"Ctrl a\"" = cmd "SwitchToMode \"normal\"";
          "bind \"Ctrl b\"" = cmd "SwitchToMode \"tmux\"";
        };
        "shared_except \"locked\" \"renametab\" \"renamepane\"" = {
          "bind \"Ctrl a\"" = cmd "SwitchToMode \"locked\"";
          "bind \"Ctrl q\"" = cmd "Quit";
        };
        "shared_except \"locked\" \"entersearch\"" = {
          "bind \"enter\"" = cmd "SwitchToMode \"locked\"";
        };
        "shared_except \"locked\" \"entersearch\" \"renametab\" \"renamepane\"" = {
          "bind \"esc\"" = cmd "SwitchToMode \"locked\"";
        };
        "shared_except \"locked\" \"entersearch\" \"renametab\" \"renamepane\" \"search\" \"session\"" = {
          "bind \"o\"" = cmd "SwitchToMode \"session\"";
        };
        "shared_except \"locked\" \"entersearch\" \"renametab\" \"renamepane\" \"tab\"" = {
          "bind \"t\"" = cmd "SwitchToMode \"tab\"";
        };
        "shared_except \"locked\" \"resize\" \"tab\" \"scroll\" \"prompt\" \"tmux\"" = {
          "bind \"p\"" = cmd "SwitchToMode \"pane\"";
        };
        "renametab" = {
          "bind \"esc\"" = cmdAndSwitchToMode "UndoRenameTab" "tab";
        };
        "renamepane" = {
          "bind \"esc\"" = cmdAndSwitchToMode "UndoRenameTab" "pane";
        };
        "shared_among \"renametab\" \"renamepane\"" = {
          "bind \"Ctrl c\"" = cmd "SwitchToMode \"locked\"";
        };
        "shared_among \"normal\" \"locked\"" = {
          "bind \"Alt left\"" = cmd "MoveFocusOrTab \"left\"";
          "bind \"Alt down\"" = cmd "MoveFocus \"down\"";
          "bind \"Alt up\"" = cmd "MoveFocus \"up\"";
          "bind \"Alt right\"" = cmd "MoveFocusOrTab \"right\"";
        };

        pane = {
          "bind \"r\"" = {
            "SwitchToMode \"renamepane\"" = {};
            "PaneNameInput 0" = {};
          };
          "bind \"f\"" = cmdAndLock "TogglePaneEmbedOrFloating";
          "bind \"Shift f\"" = cmdAndLock "ToggleFocusFullscreen";
          "bind \"n\"" = cmdAndLock "NewPane \"right\"";
          "bind \"Shift n\"" = cmdAndLock "NewPane \"down\"";
          "bind \"tab\"" = cmd "SwitchFocus";
        };

        tab = {
          "bind \"r\"" = {
            "SwitchToMode \"renametab\"" = {};
            "TabNameInput 0" = {};
          };
          "bind \"h\"" = cmd "GoToPreviousTab";
          "bind \"j\"" = cmd "GoToPreviousTab";
          "bind \"k\"" = cmd "GoToNextTab";
          "bind \"l\"" = cmd "GoToNextTab";
          "bind \"{\"" = cmd "MoveTab \"left\"";
          "bind \"}\"" = cmd "MoveTab \"right\"";
          "bind \"n\"" = cmdAndLock "NewTab";
          "bind \"1\"" = cmdAndLock "GoToTab 1";
          "bind \"2\"" = cmdAndLock "GoToTab 2";
          "bind \"3\"" = cmdAndLock "GoToTab 3";
          "bind \"4\"" = cmdAndLock "GoToTab 4";
          "bind \"5\"" = cmdAndLock "GoToTab 5";
          "bind \"6\"" = cmdAndLock "GoToTab 6";
          "bind \"7\"" = cmdAndLock "GoToTab 7";
          "bind \"8\"" = cmdAndLock "GoToTab 8";
          "bind \"9\"" = cmdAndLock "GoToTab 9";
          "bind \"b\"" = cmdAndLock "BreakPane";
          "bind \"[\"" = cmdAndLock "BreakPaneLeft";
          "bind \"]\"" = cmdAndLock "BreakPaneRight";
          "bind \"x\"" = cmdAndLock "CloseTab";
        };

        tmux = {
          # TODO: Update zmk-config to stop using tmux mode and use tab mode instead.
          "bind \"h\"" = cmdAndLock "GoToTab 1";
          "bind \"j\"" = cmdAndLock "GoToTab 2";
          "bind \"k\"" = cmdAndLock "GoToTab 3";
          "bind \"l\"" = cmdAndLock "GoToTab 4";
          "bind \"/\"" = cmd "SwitchToMode \"entersearch\"";
          "bind \"?\"" = cmd "SwitchToMode \"entersearch\"";
          "bind \"\\\"\"" = cmdAndLock "NewPane \"down\"";
          "bind \"%\"" = cmdAndLock "NewPane \"right\"";
          "bind \"c\"" = cmdAndLock "NewTab";
          "bind \"Ctrl b\"" = cmdAndLock "ToggleTab";
          "bind \"w\"" = {
            "LaunchOrFocusPlugin \"session-manager\"" = {
              floating = true;
              move_to_focused_tab = true;
            };
            "SwitchToMode \"locked\"" = {};
          };
        };

        search = {
          "bind \"c\"" = cmd "SearchToggleOption \"CaseSensitivity\"";
          "bind \"o\"" = cmd "SearchToggleOption \"WholeWord\"";
          "bind \"w\"" = cmd "SearchToggleOption \"Wrap\"";
          "bind \"[\"" = cmd "Search \"up\"";
          "bind \"]\"" = cmd "Search \"down\"";
        };

        entersearch = {
          "bind \"Ctrl c\"" = cmd "SwitchToMode \"scroll\"";
          "bind \"esc\"" = cmd "SwitchToMode \"scroll\"";
          "bind \"enter\"" = cmd "SwitchToMode \"search\"";
        };

        scroll = {
          "bind \"e\"" = cmdAndLock "EditScrollback";
          "bind \"f\"" = {
            "SwitchToMode \"entersearch\"" = {};
            "SearchInput 0" = {};
          };
        };

        session = {
          "bind \"d\"" = cmd "Detach";
          "bind \"o\"" = cmd "SwitchToMode \"normal\"";
          "bind \"p\"" = {
            "LaunchOrFocusPlugin \"plugin-manager\"" = {
              floating = true;
              move_to_focused_tab = true;
            };
            "SwitchToMode \"locked\"" = {};
          };
          "bind \"w\"" = {
            "LaunchOrFocusPlugin \"session-manager\"" = {
              floating = true;
              move_to_focused_tab = true;
            };
            "SwitchToMode \"locked\"" = {};
          };
        };

        shared = {
          "bind \"Ctrl b\"" = {"SwitchToMode \"tmux\"" = {};};
          "bind \"Ctrl f\"" = lib.mkIf (switcherApp == "zellij") {
            "MessagePlugin \"pathfinder\"" = {
              launch_new = true; # Always launch a new instance. This guarantees that CWD is correctly updated.
              skip_cache = false; # Don't skip compilation cache.
              floating = true; # Always float the plugin window.

              cwd = codeDirectory;
              name = "scan_repository_root";

              # scan_root = codeDirectory;
              # list_paths_command = "${pkgs.zellij-switch-repository}/bin/find-git-repositories";
            };
          };
        };
      };
    };
  };

  programs.fish = {
    interactiveShellInit = lib.optionalString (switcherApp == "zellij") ''
      bind           \cf '__zellij_pathfinder'
      bind -M insert \cf '__zellij_pathfinder'
    '';

    functions.__zellij_pathfinder = let
      launch_pathfinder = pkgs.writeTextFile {
        name = "launch-pathfinder.kdl";
        text = ''
          layout {
            floating_panes {
              pane {
                plugin location="pathfinder" {
                  cwd "${codeDirectory}"
                  bootstrap true
                }
              }
            }
          }
        '';
      };
    in ''
      if test -z $ZELLIJ
        command zellij --layout ${launch_pathfinder} options --default-cwd ${codeDirectory}
      end
    '';
  };
}
