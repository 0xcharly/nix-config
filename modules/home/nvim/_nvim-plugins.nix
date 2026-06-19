{ vimPlugins, colors-nvim }:
with vimPlugins;
[
  blink-cmp
  conform-nvim
  fff-nvim
  nvim-lspconfig
  nvim-treesitter.withAllGrammars
  mini-nvim
  nvim-cmp
  oil-nvim
  render-markdown-nvim
  snacks-nvim
  sqlite-lua
]
++ [ colors-nvim ]
