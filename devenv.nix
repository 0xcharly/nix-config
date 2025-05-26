{
  inputs,
  pkgs,
  ...
}: {
  packages = with pkgs; [
    cachix
    jq
    just

    alejandra

    # Formatters.
    (inputs.treefmt-nix.lib.mkWrapper pkgs (import ./treefmt.nix))
  ];

  languages.nix.enable = true;
  languages.nix.lsp.package = pkgs.nixd;
}
