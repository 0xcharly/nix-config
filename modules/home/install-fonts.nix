{
  moduleWithSystem,
  self,
  ...
}:
{
  flake.homeModules.install-fonts = moduleWithSystem (
    perSystem@{ config, ... }:
    { pkgs, ... }:
    {
      fonts.fontconfig = {
        enable = true;
        defaultFonts =
          let
            inherit (self.lib.theme.font)
              emoji
              monospace
              sansSerif
              serif
              ;
          in
          {
            monospace = [ monospace.name ];
            sansSerif = [ sansSerif.name ];
            serif = [ serif.name ];
            emoji = [ emoji.name ];
          };
      };

      home.packages =
        with pkgs;
        [
          material-design-icons
          nerd-fonts.symbols-only
          noto-fonts-color-emoji
          recursive
          sarasa-gothic
        ]
        ++ (with perSystem.config.packages; [
          iosevka
          iosevka-aile
          iosevka-etoile
          tx-02
        ]);
    }
  );

  perSystem =
    { inputs', pkgs, ... }:
    {
      packages.iosevka = pkgs.callPackage ./iosevka {
        set = "Custom";
        family = "Iosevka";
        spacing = "term";
      };
      # Quasi-proportional build of the same custom flavor, for UI text.
      packages.iosevka-aile = pkgs.callPackage ./iosevka {
        set = "CustomAile";
        family = "Iosevka Aile";
        spacing = "quasi-proportional";
      };
      packages.iosevka-bin = pkgs.callPackage ./iosevka-bin { };
      packages.iosevka-etoile = pkgs.callPackage ./iosevka-bin { variant = "Etoile"; };
      packages.tx-02 = inputs'.nix-config-unfree.packages.tx-02;
    };
}
