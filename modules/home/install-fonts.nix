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
            inherit (self.lib.user.gui.fonts)
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
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
          recursive
        ]
        ++ [ perSystem.config.packages.tx-02 ];
    }
  );

  perSystem = { inputs', ... }: {
    packages.tx-02 = inputs'.nix-config-unfree.packages.tx-02;
  };
}
