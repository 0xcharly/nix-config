{
  pkgs,
  lib,
  ...
}: {
  packages = with pkgs;
    [
      alejandra
      deploy-rs
      home-manager
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [pkgs.bitwarden-cli];

  languages.nix = {
    enable = true;
    lsp.package = pkgs.nixd;
  };

  scripts = {
    gc.exec = ''
      nix-collect-garbage --delete-older-than 7d
    '';

    remote-unlock.exec = builtins.readFile ./bin/remote-unlock.sh;

    provision-generic.exec = builtins.readFile ./bin/provision-generic.sh;
    provision-linode.exec = builtins.readFile ./bin/provision-linode.sh;
    provision-nas.exec = builtins.readFile ./bin/provision-nas.sh;

    rebuild.exec = let
      rebuildOptions = "--option accept-flake-config true --show-trace";
      switch =
        if pkgs.stdenv.isDarwin
        then ''
          sudo darwin-rebuild ${rebuildOptions} switch --flake .
        ''
        else ''
          if test $(grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"; then
            sudo nixos-rebuild ${rebuildOptions} switch --flake .
          else
            home-manager ${rebuildOptions} switch -b hm.bak --flake .
          fi
        '';
    in
      switch;

    rollback.exec = let
      rebuildOptions = "--option accept-flake-config true --show-trace";
      switch =
        if pkgs.stdenv.isDarwin
        then ''
          echo "Rollback not available on darwin."
          exit 1
        ''
        else ''
          if test $(grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"; then
            sudo nixos-rebuild ${rebuildOptions} --rollback switch --flake .
          else
            echo "Rollback not available with home-manager."
            exit 1
          fi
        '';
    in
      switch;

    cache.exec = let
      cache =
        if pkgs.stdenv.isDarwin
        then ''
          echo "Cache not available on darwin."
          exit 1
        ''
        else ''
          HOSTNAME=$(hostname)
          CONFIG=''${1:-$HOSTNAME}

          if test $(grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"; then
            CONFIG_PREFIX="nixosConfigurations"
          else
            CONFIG_PREFIX="homeConfigurations"
          fi

          nix build ".#$CONFIG_PREFIX.$CONFIG.config.system.build.toplevel" --json \
            | ${lib.getExe pkgs.jq} -r '.[].outputs | to_entries[].value' \
            | ${lib.getExe pkgs.cachix} push 0xcharly-nixos-config
        '';
    in
      cache;

    ssh-copy-terminfo.exec = ''
      ${lib.getExe' pkgs.ncurses "infocmp"} -x | ssh -o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$1" -- tic -x -
    '';
  };
}
