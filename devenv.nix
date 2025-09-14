{
  inputs,
  pkgs,
  lib,
  ...
}: {
  packages = with pkgs; [
    cachix
    deploy-rs
    jq
    just
    home-manager

    alejandra
  ] ++ lib.optionals pkgs.stdenv.isLinux [pkgs.bitwarden-cli];

  languages.nix = {
    enable = true;
    lsp.package = pkgs.nixd;
  };

  enterShell = ''
    bw config server https://vault.qyrnl.com 2> /dev/null || true
  '';

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

    fmt.exec = let
      fmt-opts = {
        projectRootFile = "flake.lock";
        programs = {
          alejandra.enable = true;
          prettier.enable = true;
          shfmt.enable = false;
        };
        settings.formatter.prettier.excludes = [
          "users/delay/walker/style.css"
          "users/delay/waybar/style.css"
        ];
      };
      fmt = inputs.treefmt-nix.lib.mkWrapper pkgs fmt-opts;
    in
      lib.getExe fmt;

    ssh-copy-terminfo.exec = let
      app = pkgs.writeShellApplication {
        name = "ssh-copy-terminfo";
        runtimeInputs = with pkgs; [ncurses];
        text = ''
          infocmp -x | ssh -o PubkeyAuthentication=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$1" -- tic -x -
        '';
      };
    in
      lib.getExe app;
  };
}
