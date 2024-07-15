{
  usrModules,
  lib,
  ...
}: {
  imports = lib.attrValues {inherit (usrModules) delay;};
}
