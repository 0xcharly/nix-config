{
  inputs,
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;

  homeDirectory = config.modules.system.users.delay.home;
  codeDirectory = homeDirectory + "/code";

  zellijDevLayout = pkgs.writeTextFile {
    name = "zellij-dev.kdl";
    text = ''
      layout {
        default_tab_template {
          children
        }
        tab name="editor" {
          // Cannot use edit= otherwise the direnv is not be loaded before the
          // editor is spawned and tools (LSP, etc…) are not available.
          // pane edit="."
          pane
        }
        tab name="shell" focus=true {
          pane
        }
      }
    '';
  };
in {
  programs.zellij = {
    enable = true;
    package = let
      pkgs' = import inputs.nixpkgs-unstable {inherit (pkgs) system;};
    in
      pkgs'.zellij;
    settings = {
      default_layout = "compact";
      default_mode = "locked";
      show_startup_tips = false;
      scrollback_editor = lib.getExe pkgs.nvim;
      pane_frames = false;
      ui.pane_frames = {
        rounded_corners = true;
        hide_session_name = true;
      };
      # Disable session resurrection. When a session is resurrected, Zellij
      # attempts to rerun the last command (fortunately behind a "Press ENTER to
      # run" banner). This is way too dangerous, but there's no way to disable
      # just this behavior. In the meantime, session resurrection is disabled.
      # https://zellij.dev/documentation/session-resurrection
      session_serialization = false;
      plugins = {
        primehopper._props.location = "file:${lib.getExe pkgs.zellij-prime-hopper}";
      };

      themes = {
        catppuccin-obsidian = {
          "bg" = "#303747"; # Cursorline.
          "fg" = "#e1e8f4";
          "red" = "#fe9aa4";
          "green" = "#92d8d2"; # Teal
          "blue" = "#95b7ef";
          "yellow" = "#f3dfb4";
          "magenta" = "#f5c2e7"; # Pink
          "orange" = "#fab387"; # Peach
          "cyan" = "#89dceb"; # Sky
          "black" = "#11161d"; # Mantle.
          "white" = "#cdd6f4";
        };
      };

      theme = "catppuccin-obsidian";

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
          "bind \"Ctrl b\"" = cmd "SwitchToMode \"normal\"";
        };
        "shared_except \"locked\" \"renametab\" \"renamepane\"" = {
          "bind \"Ctrl b\"" = cmd "SwitchToMode \"locked\"";
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
        "shared_except \"locked\" \"resize\" \"tab\" \"scroll\" \"prompt\"" = {
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

        normal = {
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
          "bind \"Alt h\"" = cmdAndLock "GoToTab 1";
          "bind \"Alt t\"" = cmdAndLock "GoToTab 2";
          "bind \"Alt n\"" = cmdAndLock "GoToTab 3";
          "bind \"Alt s\"" = cmdAndLock "GoToTab 4";
          "bind \"Ctrl b\"" = {"SwitchToMode \"normal\"" = {};};
          "bind \"Ctrl f\"" = {
            "MessagePlugin \"primehopper\"" = {
              launch_new = true; # Always launch a new instance. This guarantees that CWD is correctly updated.
              skip_cache = false; # Don't skip compilation cache.
              floating = true; # Always float the plugin window.

              layout = "file:${zellijDevLayout}";
              cwd = codeDirectory;
              name = "scan_repository_root";
            };
          };
        };
      };
    };
  };

  programs.fish = {
    interactiveShellInit = ''
      bind           \cf '__zellij_primehopper'
      bind -M insert \cf '__zellij_primehopper'
    '';

    functions.__zellij_primehopper = let
      launch_primehopper = pkgs.writeTextFile {
        name = "launch-primehopper.kdl";
        text = ''
          layout {
            floating_panes {
              pane {
                plugin location="primehopper" {
                  layout "file:${zellijDevLayout}"
                  cwd "${codeDirectory}"
                  startup_message_name "scan_repository_root"
                  startup_message_payload "5"
                }
              }
            }
          }
        '';
      };
    in ''
      if test -z $ZELLIJ
        command zellij --layout ${launch_primehopper} options --default-cwd ${codeDirectory}
      end
    '';
  };
}
