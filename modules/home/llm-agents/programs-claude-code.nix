{
  inputs,
  moduleWithSystem,
  ...
}:
{
  flake.homeModules.programs-claude-code = moduleWithSystem (
    perSystem@{ config, ... }:
    {
      home.packages = [ perSystem.config.packages.claude-code ];
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages = {
        inherit (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}) claude-code;
      };
    };
}
