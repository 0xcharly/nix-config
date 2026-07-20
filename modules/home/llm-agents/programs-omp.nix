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

      home.packages = with perSystem.config.packages; [
        omp
        fff-mcp
      ];

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
          advisor: anthropic/claude-fable-5
      '';

      # User-level MCP servers: https://github.com/can1357/oh-my-pi/blob/main/docs/mcp-config.md
      home.file.".omp/agent/mcp.json".text = builtins.toJSON {
        "$schema" =
          "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json";
        mcpServers.fff = {
          type = "stdio";
          command = "fff-mcp";
        };
      };
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages = {
        inherit (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}) omp;
        inherit (inputs.fff.packages.${pkgs.stdenv.hostPlatform.system}) fff-mcp;
      };
    };
}
