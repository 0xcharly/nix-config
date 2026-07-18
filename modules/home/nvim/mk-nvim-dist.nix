{
  stdenv,
  lib,
  # Neovim derivation helpers.
  neovim-unwrapped,
  wrapNeovimUnstable,
  neovimUtils,
  # Neovim config dependencies.
  rsync,
  # Runtime dependencies.
  fzf,
  kdlfmt,
  lua-language-server,
  nixd,
  nixfmt,
  pyright,
  ripgrep,
  ruff,
  sqlite,
  stylua,
  taplo,
  yq,
}:
let
  wrapper =
    {
      src,
      runtime ? [ ],
      patches ? [ ],
      plugins ? [ ],
    }:
    let
      # Hot-fixes to the nvim package, if any.
      package-with-patches = neovim-unwrapped.overrideAttrs (
        _final: prev: {
          patches = prev.patches ++ patches;
        }
      );

      # Packages the config into its own derivation. Excludes `init.lua` since
      # it's inlined in `luaRcContent`.
      nvim-config = stdenv.mkDerivation {
        name = "nvim-config";
        inherit src;

        buildInputs = [ rsync ];
        buildPhase = ''
          mkdir -p $out/nvim
        '';

        installPhase = ''
          rsync -a --exclude=/init.lua $src/ $out/nvim
        '';
      };

      # Wraps the user's `init.lua`.
      #
      # Ensures that the runtime path is prepended to RTP before including the
      # content of `init.lua`.
      # Ensures that `<config>/nvim` and `<config>/after` are also prepended to RTP.
      # Does this _after_ loading `init.lua` to guarantee a correct RTP order.
      luaRcContent =
        let
          prependAllToRtp = map (directory: "vim.opt.rtp:prepend('${directory}')");
          userConfig = [
            (nvim-config + /nvim)
            (nvim-config + /after)
          ];
          inlineContent = map builtins.readFile;
          inlinedConfig = [
            (src + /init.lua)
          ];
        in
        builtins.concatStringsSep "\n" (
          [
            ''
              vim.loader.enable()
            ''
          ]
          ++ (prependAllToRtp runtime)
          ++ (inlineContent inlinedConfig)
          ++ (prependAllToRtp userConfig)
        );

      # Generates command-line flags to point to the correct version of SQLite.
      sqliteWrapperArgs =
        let
          sqlitePackages = [ sqlite ];
          sqliteLibExt = stdenv.hostPlatform.extensions.sharedLibrary;
          sqliteLibPath = "${sqlite.out}/lib/libsqlite3${sqliteLibExt}";
        in
        [
          "--prefix"
          "PATH"
          ":"
          "${lib.makeBinPath sqlitePackages}"
          "--set"
          "LIBSQLITE_CLIB_PATH"
          sqliteLibPath
          "--set"
          "LIBSQLITE"
          sqliteLibPath
        ];

      runtimeDeps = [
        fzf
        kdlfmt
        lua-language-server
        nixd
        nixfmt
        pyright
        ripgrep
        ruff
        stylua
        taplo
        yq
      ];
      runtimeDepsWrapperArgs = [
        "--prefix"
        "PATH"
        ":"
        "${lib.makeBinPath runtimeDeps}"
      ];
    in
    wrapNeovimUnstable package-with-patches {
      inherit luaRcContent;
      wrapRc = true;

      viAlias = false;
      vimAlias = false;
      withNodeJs = false;
      withPython3 = false;
      withRuby = false;
      withSqlite = true;

      plugins = neovimUtils.normalizePlugins plugins;
      wrapperArgs = lib.escapeShellArgs (sqliteWrapperArgs ++ runtimeDepsWrapperArgs);
    };
in
lib.makeOverridable wrapper
