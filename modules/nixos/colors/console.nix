{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs.lib) lists;
  colors = self.lib.colors.noPrefix;
in
{
  flake.nixosModules.colors-console = {
    console.colors = map (index: colors."terminal_color_${toString index}") (lists.range 0 15);
  };
}
