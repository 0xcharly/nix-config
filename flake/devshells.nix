{
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
        alejandra
        markdownlint-cli
        nixd
      ];

      shellHook = ''
        ${config.pre-commit.installationScript}
      '';
    };

    pre-commit = {
      inherit pkgs;
      settings = {
        hooks = {
          alejandra.enable = true;
          markdownlint = {
            enable = true;
            settings.configuration.MD034 = false;
          };
        };
      };
    };
  };
}
