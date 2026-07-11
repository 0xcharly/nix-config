{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  packages = with pkgs; [ kdePackages.qtdeclarative ];

  languages = {
    lua.enable = true;
    nix = {
      enable = true;
      lsp.package = pkgs.nixd;
    };
  };

  enterShell =
    let
      pkgs' = import inputs.nixpkgs {
        inherit (pkgs.stdenv.hostPlatform) system;
        overlays = [ inputs.gen-luarc.overlays.default ];
      };
      luarc-json = pkgs'.mk-luarc-json {
        plugins = pkgs.callPackage ./modules/home/nvim/_nvim-plugins.nix {
          splicedpixel-nvim = pkgs.callPackage ./modules/home/vimPlugins/_splicedpixel-nvim {
            splicedpixel = pkgs.callPackage ./modules/lib/_splicedpixel { };
          };
        };
        nvim = pkgs.neovim-unwrapped;
      };
    in
    ''
      ln -fs ${luarc-json} .luarc.json
    '';
  scripts =
    let
      inhibit = why: command: ''
        ${lib.getExe' pkgs.systemd "systemd-inhibit"} --what=idle --who=$(whoami) --why='${why}' ${command}
      '';
      nixExperimentalFeaturesOption = ''extra-experimental-features "flakes nix-command pipe-operators"'';
      rebuildOptions = "--sudo --show-trace --option ${nixExperimentalFeaturesOption}";
    in
    {
      format.exec =
        let
          fmt-opts = {
            projectRootFile = "flake.lock";
            programs = {
              nixfmt.enable = true;
              shfmt.enable = true;
              stylua.enable = true;
            };
          };
          format = inputs.treefmt-nix.lib.mkWrapper pkgs fmt-opts;
        in
        lib.getExe format;

      gc.exec = ''
        nix-collect-garbage --delete-older-than 7d
      '';

      unlock.exec = builtins.readFile ./bin/unlock.sh;

      provision-generic = {
        exec = builtins.readFile ./bin/provision-generic.sh;
        packages = with pkgs; [
          bitwarden-cli
          jq
        ];
      };
      provision-linode = {
        exec = builtins.readFile ./bin/provision-linode.sh;
        packages = with pkgs; [
          bitwarden-cli
          jq
        ];
      };
      provision-nas = {
        exec = builtins.readFile ./bin/provision-nas.sh;
        packages = with pkgs; [
          bitwarden-cli
          jq
        ];
      };

      check.exec = ''
        ${lib.getExe pkgs.gum} log --time=datetime --level=info "Validating configuration."
        nix flake check --show-trace --${nixExperimentalFeaturesOption}
      '';

      build.exec = ''
        ${lib.getExe pkgs.gum} log --time=datetime --level=info "Building NixOS system."
        ${inhibit "Building NixOS system" "nixos-rebuild ${rebuildOptions} build --flake ."}

        if test $? -eq 0; then
          ${lib.getExe pkgs.nvd} diff /run/current-system result
        fi
      '';

      rebuild.exec = ''
        ${lib.getExe pkgs.gum} log --time=datetime --level=info "Building NixOS system."
        ${inhibit "Building NixOS system" "nixos-rebuild ${rebuildOptions} build --flake ."}

        if test $? -eq 0; then
          ${lib.getExe pkgs.nvd} diff /run/current-system result
          ${lib.getExe pkgs.gum} log --time=datetime --level=info "Switching to last NixOS system generation."
          ${inhibit "Switching to last NixOS system generation" "nixos-rebuild ${rebuildOptions} switch --flake ."}
        fi
      '';

      sys-upgrade.exec = ''
        ${lib.getExe pkgs.gum} log --time=datetime --level=info "Upgrading NixOS system."
        ${inhibit "Upgrading NixOS system" "nixos-rebuild ${rebuildOptions} boot --flake ."}
        if test $? -eq 0; then
          ${lib.getExe pkgs.gum} log --time=datetime --level=info "NixOS system upgraded. Reboot to apply changes."
        fi
      '';

      rollback.exec = ''
        ${lib.getExe pkgs.gum} log --time=datetime --level=info "Rolling back NixOS system."
        ${inhibit "Rolling back NixOS system" "sudo nixos-rebuild ${rebuildOptions} --rollback switch --flake ."}
      '';

      remote-rebuild.exec = ''
        HOSTNAME=''${1}

        ${lib.getExe pkgs.gum} log --structured --time=datetime --level=info "Rebuilding remote NixOS system." host $HOSTNAME
        ${inhibit "Rebuilding NixOS system" "nixos-rebuild ${rebuildOptions} switch --flake .#$HOSTNAME --target-host root@$HOSTNAME"}
      '';

      remote-sys-upgrade.exec = ''
        HOSTNAME=''${1}

        ${lib.getExe pkgs.gum} log --structured --time=datetime --level=info "Upgrading remote NixOS system." host $HOSTNAME
        ${inhibit "Upgrading NixOS system" "nixos-rebuild ${rebuildOptions} boot --flake .#$HOSTNAME --target-host root@$HOSTNAME"}
        if test $? -eq 0; then
          ${lib.getExe pkgs.gum} log --time=datetime --level=info "NixOS system upgraded. Reboot to apply changes."
        fi
      '';

      deploy.exec = ''
        HOSTNAME=''${1}
        shift

        ${lib.getExe pkgs.gum} log --structured --time=datetime --level=info "Updating deploy flake lock file" file hive/flake.lock
        nix flake update --flake ?dir=hive nix-config

        if test $? -eq 0; then
          ${lib.getExe pkgs.gum} log --structured --time=datetime --level=info "Deploying NixOS systems." host $HOSTNAME
          ${inhibit "Deploying NixOS systems" "${lib.getExe pkgs.deploy-rs} \"./hive#$HOSTNAME\" $@ -- --show-trace --${nixExperimentalFeaturesOption}"}
        fi
      '';

      cache.exec = ''
        HOSTNAME=$(hostname)
        CONFIG=''${1:-$HOSTNAME}

        ${lib.getExe pkgs.gum} log --structured --time=datetime --level=info "Building and caching NixOS system closure." config $CONFIG
        ${inhibit "Building and caching NixOS system closure" ''
          nix build ".#nixosConfigurations.$CONFIG.config.system.build.toplevel" --json \
            | ${lib.getExe pkgs.jq} -r '.[].outputs | to_entries[].value' \
            | ${lib.getExe pkgs.cachix} push 0xcharly-nixos-config
        ''}
      '';

      preview-avatar.exec = ''
        ${lib.getExe pkgs.glslviewer} --uniform -h 1024 -w 1024 data/avatar.frag
      '';

      ssh-copy-terminfo.exec = ''
        ${lib.getExe' pkgs.ncurses "infocmp"} -x | ssh -o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$1" -- tic -x -
      '';

      generate-colorscheme.exec = ''
        nix run .#splicedpixel -- render --config modules/lib/_colors/theme.toml --format json -o modules/lib/_colors/colors.json
      '';

      update-tailwind-palette.exec = ''
        nix run .#splicedpixel -- update-palette -o modules/lib/_splicedpixel/tailwind.json
      '';
    };
}
