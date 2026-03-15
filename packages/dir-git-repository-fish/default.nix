{
  pkgs,
  pname,
  ...
}:
with pkgs;
fishPlugins.buildFishPlugin {
  inherit pname;
  version = "2026-03-15";

  src = ./.;

  buildInput = [
    fzf
    git
  ];

  meta = with lib; {
    description = "Quick navigation to local checkouts following the `pkgs.git-get` structure";
    license = licenses.mit;
    maintainers = [ lib.maintainers._0xcharly ];
    platforms = platforms.unix;
  };
}
