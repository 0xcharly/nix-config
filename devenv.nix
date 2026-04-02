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
      nix-output-monitor # Nix Output Monitor.

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
      rebuildOptions = "--option accept-flake-config true --show-trace";
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

      rebuild.exec =
        if pkgs.stdenv.isDarwin then
          ''
            sudo darwin-rebuild ${rebuildOptions} switch --flake .
          ''
        else
          ''
            if test $(grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"; then
              ${inhibit "Rebuilding NixOS system" "sudo nixos-rebuild ${rebuildOptions} switch --flake ."}
            else
              ${inhibit "Rebuilding home-manager config" "${lib.getExe pkgs.home-manager} ${rebuildOptions} switch -b hm.bak --flake ."}
            fi
          '';

      rollback.exec =
        if pkgs.stdenv.isDarwin then
          ''
            >&2 echo "`rollback` not available on darwin."
            exit 1
          ''
        else
          ''
            if test $(grep ^NAME= /etc/os-release | cut -d= -f2) != "NixOS"; then
              echo "`rollback` not available with home-manager."
              exit 1
            fi

            ${inhibit "Rolling back NixOS system" "sudo nixos-rebuild ${rebuildOptions} --rollback switch --flake ."}
          '';

      cache.exec =
        if pkgs.stdenv.isDarwin then
          ''
            >&2 echo "`cache` not available on darwin."
            exit 1
          ''
        else
          ''
            HOSTNAME=$(hostname)
            CONFIG=''${1:-$HOSTNAME}

            if test $(grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"; then
              CONFIG_PREFIX="nixosConfigurations"
            else
              CONFIG_PREFIX="homeConfigurations"
            fi

            ${inhibit "Building and caching NixOS system closure" ''
              nix build ".#$CONFIG_PREFIX.$CONFIG.config.system.build.toplevel" --json \
                | ${lib.getExe pkgs.jq} -r '.[].outputs | to_entries[].value' \
                | ${lib.getExe pkgs.cachix} push 0xcharly-nixos-config
            ''}
          '';

      deploy.exec =
        if pkgs.stdenv.isDarwin then
          ''
            >&2 echo "`deploy` not available on darwin."
            exit 1
          ''
        else
          ''
            if test $(grep ^NAME= /etc/os-release | cut -d= -f2) != "NixOS"; then
              >&2 echo "`deploy` not available on non-NixOS systems."
              exit 1
            fi

            ${inhibit "Deploying NixOS systems" "${lib.getExe pkgs.deploy-rs} ''$@"}
          '';

      preview-avatar.exec =
        if pkgs.stdenv.isDarwin then
          ''
            >&2 echo "`preview-avatar` not available on darwin."
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
