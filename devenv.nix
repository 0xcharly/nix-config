{
  pkgs,
  lib,
  ...
}:
{
  packages =
    with pkgs;
    [
      nixfmt
      nix-output-monitor # Nix Output Monitor

      jq
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.bitwarden-cli ];

  languages.nix = {
    enable = true;
    lsp.package = pkgs.nixd;
  };

  scripts =
    let
      inhibit = why: command: ''
        ${lib.getExe' pkgs.systemd "systemd-inhibit"} --what=idle --who=$(whoami) --why='${why}' ${command}
      '';
      nixExperimentalFeaturesOption = ''extra-experimental-features "flakes nix-command pipe-operators"'';
      rebuildOptions = "--sudo --show-trace --option ${nixExperimentalFeaturesOption}";
    in
    {
      gc.exec = ''
        nix-collect-garbage --delete-older-than 7d
      '';

      remote-unlock.exec = builtins.readFile ./bin/remote-unlock.sh;
      remote-unlock-emergency.exec = builtins.readFile ./bin/remote-unlock-emergency.sh;

      provision-generic.exec = builtins.readFile ./bin/provision-generic.sh;
      provision-linode.exec = builtins.readFile ./bin/provision-linode.sh;
      provision-nas.exec = builtins.readFile ./bin/provision-nas.sh;

      check.exec = ''
        ${lib.getExe pkgs.gum} log --time=datetime --level=info "Validating configuration."
        nix flake check --show-trace --${nixExperimentalFeaturesOption}
      '';

      build.exec =
        if pkgs.stdenv.isDarwin then
          ''
            ${lib.getExe pkgs.gum} log --time=datetime --level=info "Building nix-darwin system."
            darwin-rebuild ${rebuildOptions} build --flake .
          ''
        else
          ''
            ${lib.getExe pkgs.gum} log --time=datetime --level=info "Building NixOS system."
            ${inhibit "Building NixOS system" "nixos-rebuild ${rebuildOptions} build --flake ."}

            if test $? -eq 0; then
              ${lib.getExe pkgs.nvd} diff /run/current-system result
            fi
          '';

      rebuild.exec =
        if pkgs.stdenv.isDarwin then
          ''
            ${lib.getExe pkgs.gum} log --time=datetime --level=info "Rebuilding nix-darwin system."
            darwin-rebuild ${rebuildOptions} switch --flake .
          ''
        else
          ''
            ${lib.getExe pkgs.gum} log --time=datetime --level=info "Rebuilding NixOS system."
            ${inhibit "Rebuilding NixOS system" "nixos-rebuild ${rebuildOptions} switch --flake ."}
          '';

      sys-upgrade.exec =
        if pkgs.stdenv.isDarwin then
          ''
            ${lib.getExe pkgs.gum} format -- '`sys-upgrade` not available on darwin.' | xargs -0 ${lib.getExe pkgs.gum} log --time=datetime --level=error
            exit 1
          ''
        else
          ''
            ${lib.getExe pkgs.gum} log --time=datetime --level=info "Upgrading NixOS system."
            ${inhibit "Upgrading NixOS system" "nixos-rebuild ${rebuildOptions} boot --flake ."}
            if test $? -eq 0; then
              ${lib.getExe pkgs.gum} log --time=datetime --level=info "NixOS system upgraded. Reboot to apply changes."
            fi
          '';

      rollback.exec =
        if pkgs.stdenv.isDarwin then
          ''
            ${lib.getExe pkgs.gum} format -- '`rollback` not available on darwin.' | xargs -0 ${lib.getExe pkgs.gum} log --time=datetime --level=error
            exit 1
          ''
        else
          ''
            ${lib.getExe pkgs.gum} log --time=datetime --level=info "Rolling back NixOS system."
            ${inhibit "Rolling back NixOS system" "sudo nixos-rebuild ${rebuildOptions} --rollback switch --flake ."}
          '';

      remote-rebuild.exec =
        if pkgs.stdenv.isDarwin then
          ''
            ${lib.getExe pkgs.gum} format -- '`remote-rebuild` not available on darwin.' | xargs -0 ${lib.getExe pkgs.gum} log --time=datetime --level=error
            exit 1
          ''
        else
          ''
            HOSTNAME=''${1}

            ${lib.getExe pkgs.gum} log --structured --time=datetime --level=info "Rebuilding remote NixOS system." host $HOSTNAME
            ${inhibit "Rebuilding NixOS system" "nixos-rebuild ${rebuildOptions} switch --flake .#$HOSTNAME --target-host root@$HOSTNAME"}
          '';

      cache.exec =
        if pkgs.stdenv.isDarwin then
          ''
            ${lib.getExe pkgs.gum} format -- '`cache` not available on darwin.' | xargs -0 ${lib.getExe pkgs.gum} log --time=datetime --level=error
            exit 1
          ''
        else
          ''
            HOSTNAME=$(hostname)
            CONFIG=''${1:-$HOSTNAME}

            ${lib.getExe pkgs.gum} log --structured --time=datetime --level=info "Building and caching NixOS system closure." config $CONFIG
            ${inhibit "Building and caching NixOS system closure" ''
              nix build ".#$nixosConfigurations.$CONFIG.config.system.build.toplevel" --json \
                | ${lib.getExe pkgs.jq} -r '.[].outputs | to_entries[].value' \
                | ${lib.getExe pkgs.cachix} push 0xcharly-nixos-config
            ''}
          '';

      preview-avatar.exec =
        if pkgs.stdenv.isDarwin then
          ''
            ${lib.getExe pkgs.gum} format -- '`preview-avatar` not available on darwin.' | xargs -0 ${lib.getExe pkgs.gum} log --time=datetime --level=error
            exit 1
          ''
        else
          ''
            ${lib.getExe pkgs.glslviewer} --uniform -h 1024 -w 1024 data/avatar.frag
          '';

      ssh-copy-terminfo.exec = ''
        ${lib.getExe' pkgs.ncurses "infocmp"} -x | ssh -o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$1" -- tic -x -
      '';
    };
}
