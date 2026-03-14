{ flake, ... }:
{ config, lib, ... }:
{
  imports = [
    flake.modules.home.ghostty
    flake.modules.home.kitty
  ];

  options.user.terminal.default = with lib; {
    name = mkOption {
      type = types.str;
      default = config.user.terminal.default.package.pname;
      description = "The short string name of the default terminal";
    };

    package = mkOption {
      type = types.package;
      default = config.programs.ghostty.package;
      description = "The default terminal to use";
    };
  };

  config = {
    home.packages = [
      config.programs.ghostty.package.terminfo
      config.programs.kitty.package.terminfo
    ];

    programs.tmux.terminal = lib.mkDefault "xterm-${config.user.terminal.default.name}";
  };
}
