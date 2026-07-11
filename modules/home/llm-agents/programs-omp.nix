{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
{
  flake.homeModules.programs-omp = moduleWithSystem (
    perSystem@{ config, ... }:
    {
      imports = [ self.homeModules.colors-omp ];

      home.packages = [ perSystem.config.packages.omp ];

      # Global omp settings: https://github.com/can1357/oh-my-pi/blob/main/docs/settings.md
      # `theme.dark` selects the theme rendered on dark terminal backgrounds.
      home.file.".omp/agent/config.yml".text = ''
        setupVersion: 1
        symbolPreset: nerd
        theme:
          dark: ${self.lib.colors.name}
        providers:
          webSearch: auto
        modelRoles:
          default: anthropic/claude-fable-5
      '';
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages = {
        inherit (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}) omp;
      };
    };
}
