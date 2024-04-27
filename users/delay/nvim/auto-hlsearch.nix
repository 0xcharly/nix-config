{ pkgs, ...}:
{
  plugin = pkgs.vimPlugins.auto-hlsearch-nvim;
  config = ''
    lua require 'auto-hlsearch'.setup()
  '';
}
