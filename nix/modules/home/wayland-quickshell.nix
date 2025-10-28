{inputs, ...}: {
  config,
  lib,
  ...
}: {
  imports = [inputs.nix-config-shell.homeManagerModules.default];

  options.node.wayland.arcshell = with lib; {
    modules = {
      battery = mkEnableOption "Enable the battery module";
    };
  };

  config = let
    cfg = config.node.wayland.arcshell;
  in {
    programs.arcshell = {
      enable = true;
      systemd.enable = true;
    };
  };
}
