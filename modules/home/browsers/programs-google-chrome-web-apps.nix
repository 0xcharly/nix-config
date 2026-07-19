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
      # reproducible fetches. Not all upstream PNGs are square, so pad each to
      # 512x512 to honor the hicolor directory below. PNG32: pins the output
      # to truecolor RGBA — otherwise ImageMagick palettizes low-color icons
      # (indexed + tRNS), which Quickshell's launcher fails to render.
      iconRev = "46b860c70e866212311aef2f98da3775c17f5068";
      fetchIcon =
        name: hash:
        let
          src = pkgs.fetchurl {
            url = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons@${iconRev}/png/${name}.png";
            inherit hash;
          };
        in
        pkgs.runCommand "webapp-icon-${name}.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
          magick ${src} -resize 512x512 -background none -gravity center -extent 512x512 PNG32:$out
        '';

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
        x = {
          name = "X";
          url = "https://x.com";
          icon = fetchIcon "x" "sha256-Mqfi3t5eKflHJKJn+WdD/ekxA4w/O+E4At4Vm1SHkeI=";
        };
        youtube = {
          name = "YouTube";
          url = "https://www.youtube.com";
          icon = fetchIcon "youtube" "sha256-IXEiZv0BxEfja0Rh/4YSRzXEg8iSElLAEfCkNUcDFVI=";
        };
        twitch = {
          name = "Twitch";
          url = "https://www.twitch.tv";
          icon = fetchIcon "twitch" "sha256-cEEqlsGKyDIQ2Q5zbTYBLn9k6i/f5a+2FUbebaywYVg=";
        };
        proton-mail = {
          name = "Proton Mail";
          url = "https://mail.proton.me";
          icon = fetchIcon "proton-mail" "sha256-JPOsxYjYUXGB6QKr2uarhjlr87UI/cvYmx2SvgBNXos=";
        };
        proton-calendar = {
          name = "Proton Calendar";
          url = "https://calendar.proton.me";
          icon = fetchIcon "proton-calendar" "sha256-W+xEWoVQlBe3yr0j5LMRQeQug8+CLCUrLg01D5YyAyo=";
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
