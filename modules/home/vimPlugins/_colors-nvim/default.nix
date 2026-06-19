{
  vimUtils,
  writeText,
  colors,
  ...
}:
(vimUtils.buildVimPlugin {
  pname = "colorscheme-nvim";
  version = "0.0.1";
  src = ./.;
}).overrideAttrs
  {
    colors = import ./colors.lua.nix colors.asHexLiterals |> writeText "colors.lua";

    buildPhase = ''
      mkdir -p $out/plugin
    '';

    installPhase = ''
      cp $colors $out/plugin/init.lua
    '';
  }
