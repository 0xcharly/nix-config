{
  usrModules,
  lib,
  ...
}: {
  imports = lib.attrValues {inherit (usrModules) delay nix-index;};
  home = {
    username = "delay";
    homeDirectory = "/home/delay";
  };
}
