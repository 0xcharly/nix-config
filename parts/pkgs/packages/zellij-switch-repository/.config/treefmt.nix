{
  projectRootFile = "flake.nix";
  settings.global.excludes = [
    ".direnv/*"
    ".env"
    ".envrc"
    ".gitignore"
    "target/*"
  ];
  programs = {
    alejandra.enable = true;
    just.enable = true;
    prettier.enable = true;
    rustfmt.enable = true;
  };
}
