{
  imports = [
    ./nix-client-config.nix
    ./overlays.nix
    # NOTE: Support for Agenix secrets is disabled because there's currently no
    # need for it.
    # Agenix is best suited for secrets stored in files referenced from configs
    # as opposed to stored in plain text in said config.
    # None of the secrets I could be using it for can be stored in files.
    # TODO: Reconsider if/when https://github.com/NixOS/nix/issues/6536 lands.
    # ./secrets.nix
  ];
}
