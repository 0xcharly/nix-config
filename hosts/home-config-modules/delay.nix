{
  hmSharedModules,
  lib,
  ...
}: {
  imports = lib.attrValues {inherit (hmSharedModules) delay;};
}
