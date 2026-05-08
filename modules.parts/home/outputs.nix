{ inputs, ... }:
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];
  systems = import inputs.systems;
}
