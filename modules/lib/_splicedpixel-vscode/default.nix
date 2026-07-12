{
  lib,
  vscode-utils,
  jq,
  splicedpixel,
}:
vscode-utils.buildVscodeExtension {
  pname = "splicedpixel-vscode";
  version = "0.0.1";

  vscodeExtPublisher = "0xcharly";
  vscodeExtName = "splicedpixel";
  vscodeExtUniqueId = "0xcharly.splicedpixel";

  # No src archive: the extension is assembled from checked-in files, with
  # the palette rendered from theme.toml at build time (same idea as
  # modules/home/vimPlugins/_splicedpixel-nvim: editing the theme only
  # rebuilds this derivation, not the splicedpixel binary).
  dontUnpack = true;

  nativeBuildInputs = [ jq ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/$installPrefix/themes"
    cp ${./package.json} "$out/$installPrefix/package.json"

    ${lib.getExe splicedpixel} render \
      --config ${../_colors/theme.toml} \
      --format json > tokens.json

    # Substitute "$token" / "$token/AA" string values with "#rrggbb[AA]".
    # The rendered hex carries no '#' (internal/color/color.go); an unknown
    # token name aborts the build.
    jq --slurpfile t tokens.json '
      def resolve:
        capture("^[$](?<n>[A-Za-z0-9_]+)(/(?<a>[0-9a-fA-F]{2}))?$") as $m
        | "#"
          + ($t[0].tokens[$m.n].hex // error("unknown theme token: " + $m.n))
          + ($m.a // "");
      walk(if type == "string" and startswith("$") then resolve else . end)
    ' ${./themes/splicedpixel-color-theme.json} \
      > "$out/$installPrefix/themes/splicedpixel-color-theme.json"

    runHook postInstall
  '';
}
