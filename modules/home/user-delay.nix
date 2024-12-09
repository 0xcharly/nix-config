{config, ...}: {
  home = let
    inherit (config.modules.system.users) delay;
  in {
    username = delay.name;
    homeDirectory = delay.home;
  };
}
