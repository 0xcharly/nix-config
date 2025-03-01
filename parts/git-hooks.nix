{inputs, ...}: {
  imports = [inputs.git-hooks-nix.flakeModule];

  perSystem = {pkgs, ...}: {
    pre-commit = {
      inherit pkgs;
      settings = {
        hooks = {
          alejandra.enable = true;
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
