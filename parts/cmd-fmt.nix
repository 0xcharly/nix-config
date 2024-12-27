{inputs, ...}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = {config, ...}: {
    formatter = config.treefmt.build.wrapper;

    treefmt = {
      projectRootFile = "flake.nix";

      programs = {
        alejandra.enable = true;
        black.enable = true;
        just.enable = true;
        prettier.enable = true;
        rustfmt.enable = true;

        shfmt = {
          enable = true;
          # https://flake.parts/options/treefmt-nix.html#opt-perSystem.treefmt.programs.shfmt.indent_size
          indent_size = 2; # set to 0 to use tabs
        };
      };

      settings.global.excludes = [
        "*.glsl"
        "*.kdl"
        "*.png"
        "*.toml"
        "*/Xresources"
        "*/tmux.conf"
        ".env"
        ".envrc"
        ".gitattributes"
        "LICENSE"
      ];
    };
  };
}
