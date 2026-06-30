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

    disko.url = "github:nix-community/disko"; # Filesystem management
    golink.url = "github:tailscale/golink"; # go/link service

    # Nix packages for AI coding agents and development tools
    llm-agents.url = "github:numtide/llm-agents.nix";
    # Antigravity tool suite
    antigravity-nix.url = "github:jacopone/antigravity-nix";


    # Nix index database, comma, command-not-found.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    # Secrets management
    nix-config-secrets.url = "github:0xcharly/nix-config-secrets";

    # Out of the box mailserver
    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";
  };

  nixConfig = {
    extra-substituters = [
      "https://0xcharly-nixos-config.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
}
