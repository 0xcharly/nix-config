{
  description = "Nix systems and configs for delay";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Manages home directory, dotfiles and base environment
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    systems.url = "github:nix-systems/default";

    disko.url = "github:nix-community/disko"; # Filesystem management
    golink.url = "github:tailscale/golink"; # go/link service

    # Tailscale SSH server for initrd
    hoopsnake = {
      url = "github:boinkor-net/hoopsnake";
      inputs = {
        flake-parts.follows = "flake-parts";
        devshell.follows = "";
        generate-go-sri.follows = "";
        nixpkgs.follows = "nixpkgs";
      };
    };

    nix-config-colorscheme.url = "github:0xcharly/nix-config-colorscheme"; # Custom colorscheme
    nix-config-secrets.url = "github:0xcharly/nix-config-secrets"; # Secrets management

    # Quickshell
    nix-config-shell = {
      url = "github:0xcharly/nix-config-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Out of the box mailserver
    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";

    # pieceofenglish.fr
    pieceofenglish.url = "github:0xcharly/pieceofenglish";
  };

  nixConfig = {
    extra-substituters = [ "https://0xcharly-nixos-config.cachix.org" ];
    extra-trusted-public-keys = [
      "0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="
    ];
  };
}
