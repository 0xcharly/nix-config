{
  lib,
  vimUtils,
  splicedpixel,
}:
vimUtils.buildVimPlugin {
  pname = "splicedpixel-nvim";
  version = "0.0.1";

  src = ./.;

  # Render the palette module from theme.toml at build time: editing the
  # theme only rebuilds this derivation, not the splicedpixel binary.
  postInstall = ''
    mkdir -p $out/lua/splicedpixel
    ${lib.getExe splicedpixel} render \
      --config ${../../../lib/internal/colors/theme.toml} \
      --format lua > $out/lua/splicedpixel/palette.lua
  '';
}
