{pkgs, ...}: {
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = ["Recursive Mono Casual Static"];
      sansSerif = ["Recursive Sans Casual Static"];
      serif = ["Recursive Sans Linear Static"];
    };
  };

  home.packages = with pkgs; [
    material-design-icons
    nerd-fonts.symbols-only
    noto-fonts-cjk-sans # CJK fonts.
    recursive # Variable font family for code & UI.
  ];
}
