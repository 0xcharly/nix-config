{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
{
  flake.homeModules.programs-llm-agents = moduleWithSystem (
    perSystem@{ config, ... }:
    {
      imports = [ self.homeModules.programs-omp ];

      # Daily pre-built binaries are available from the Numtide binary cache.
      nix.settings = {
        extra-substituters = [ "https://cache.numtide.com" ];
        extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
      };

      programs.opencode = {
        enable = true;
        package = perSystem.config.packages.opencode;
      };
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; {
        inherit opencode;
      };
    };
}
