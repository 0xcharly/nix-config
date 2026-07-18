# Auto-discovery of flake-parts modules (in-repo replacement for
# vic/import-tree): every `*.nix` file under `modules/` is imported
# automatically; adding a file wires it in.
#
# A directory containing a `.skip-subtree` sentinel file is not traversed:
# it holds support material (packages, helper libs, data) rather than
# flake-parts modules. Entries whose name starts with `.` are ignored.
# Discovery is otherwise name-agnostic.
#
# Pure builtins on purpose: `imports` may not depend on module arguments.
let
  sentinel = ".skip-subtree";

  hasSuffix =
    suffix: str:
    let
      lenSuffix = builtins.stringLength suffix;
      lenStr = builtins.stringLength str;
    in
    lenStr >= lenSuffix && builtins.substring (lenStr - lenSuffix) lenSuffix str == suffix;

  listModules =
    dir:
    let
      entries = builtins.readDir dir;
    in
    if builtins.hasAttr sentinel entries then
      [ ]
    else
      builtins.concatMap (
        name:
        if builtins.substring 0 1 name == "." then
          [ ]
        else if entries.${name} == "directory" then
          listModules (dir + "/${name}")
        else if hasSuffix ".nix" name then
          [ (dir + "/${name}") ]
        else
          [ ]
      ) (builtins.attrNames entries);
in
{
  # This file is itself discovered; drop it from the list because flake.nix
  # already passes it to mkFlake as the entry module — the module system does
  # not break import cycles, so a self-import would recurse forever.
  imports = builtins.filter (path: path != ./module-tree.nix) (listModules ../.);
}
