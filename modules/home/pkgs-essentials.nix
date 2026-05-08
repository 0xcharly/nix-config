{ flake, inputs, ... }:
{ pkgs, ... }:
{
  imports = with inputs.nix-config-colorscheme.homeModules; [
    bat
    bottom
    fzf
  ];

  # Packages I always want installed. Most packages I install using per-project
  # flakes sourced with direnv and nix-shell, so this is not a huge list.
  home.packages = with pkgs; [
    coreutils # For consistency across platforms (i.e. GNU utils on macOS).
    duf # Modern `df` alternative.
    libqalculate # Multi-purpose calculator on the command line.
    tree # List the content of directories in a tree-like format.
    yazi # File explorer that supports Kitty image protocol.

    flake.packages.${pkgs.stdenv.hostPlatform.system}.nvim # Our own package.
  ];

  programs = {
    bash.enable = true;
    bat.enable = true;
    bottom.enable = true;
    fzf.enable = true;
    ripgrep.enable = true;
  };
}
