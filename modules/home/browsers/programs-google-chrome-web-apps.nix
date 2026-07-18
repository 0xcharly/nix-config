{
  flake.homeModules.programs-google-chrome-web-apps =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      # Icons from the dashboard-icons collection, pinned to a commit for
      # reproducible fetches (512x512 RGBA PNGs, verified 2026-07-18).
      iconRev = "46b860c70e866212311aef2f98da3775c17f5068";
      fetchIcon =
        name: hash:
        pkgs.fetchurl {
          url = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons@${iconRev}/png/${name}.png";
          inherit hash;
        };

      webApps = {
        claude = {
          name = "Claude";
          url = "https://claude.ai";
          icon = fetchIcon "claude-ai" "sha256-76HQVfcmqUniwXKBC/E5DiaIdUMR0K3oVWA26HwSdfA=";
        };
        chatgpt = {
          name = "ChatGPT";
          url = "https://chatgpt.com";
          icon = fetchIcon "chatgpt" "sha256-TogafwFxgWgUOHSNJAkkChBOF2SGCEe0nolK+sAy9a0=";
        };
        gemini = {
          name = "Gemini";
          url = "https://gemini.google.com";
          icon = fetchIcon "google-gemini" "sha256-5sV/u5bwvqZULMiGLjbyXZ8D7y7K6fJ0sPgJAYFwV+8=";
        };
      };

      chrome = lib.getExe config.programs.chromium.package;
      host = app: builtins.elemAt (builtins.match "https://([^/]+).*" app.url) 0;
    in
    {
      xdg.desktopEntries = builtins.mapAttrs (id: app: {
        inherit (app) name;
        exec = "${chrome} --app=${app.url}";
        icon = "webapp-${id}";
        terminal = false;
        categories = [ "Network" ];
        # Wayland app_id Chrome assigns to --app windows; used for XWayland
        # fallback grouping only (Hyprland matches app_id directly).
        settings.StartupWMClass = "chrome-${host app}__-Default";
      }) webApps;

      # Install icons by name into the hicolor theme so launchers resolve
      # them through normal icon lookup instead of absolute store paths.
      xdg.dataFile = lib.mapAttrs' (
        id: app: lib.nameValuePair "icons/hicolor/512x512/apps/webapp-${id}.png" { source = app.icon; }
      ) webApps;
    };
}
