# Neovim

This is a custom Neovim "distribution" that is bundled into a single Nix
derivation.

This config tries to strike a balance between helpful features and limited
number of plugins.

Give it a try!

```bash
$ nix run github:0xcharly/nix-config-nvim
```

## Extensibility

This config can be customized through one of the builders exposed in the
`flake.nix` file or using the derivation overrides, e.g.:

```nix
nixpkgs.overlays = [
  inputs.nix-config-nvim.overlays.default
  (final: prev: {
    nvim = prev.nix-config-nvim.default.override (
      prev: {
        patches = [ … ];
        plugins = prev.plugins ++ [final.extra-nvim-plugin];
      }
    );
  )
];
```
