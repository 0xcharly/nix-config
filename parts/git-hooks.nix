{inputs, ...}: {
  imports = [
    inputs.git-hooks-nix.flakeModule
  ];

  perSystem = {pkgs, ...}: {
    pre-commit = {
      inherit pkgs;
      settings = {
        hooks = {
          alejandra.enable = true;
          # TODO: enable when the static analyzer can resolve the `vim` module.
          # luacheck.enable = true;
          markdownlint = {
            enable = true;
            settings.configuration = {
              MD034 = false;
              MD040 = false; # fenced-code-language
              MD013 = false; # line-length
            };
          };
        };
      };
    };
  };
}
