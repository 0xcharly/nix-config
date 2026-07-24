{
  lib,
  buildGoModule,
  makeWrapper,
  mpv,
}:
buildGoModule {
  pname = "poolside";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-nLK/mnC9prGIqFScW4wxXntAYXC53OXZrhLY1a/B7/g=";

  nativeBuildInputs = [ makeWrapper ];
  # Playback delegates to mpv over its JSON IPC socket; pin it on PATH so the
  # binary works without a system-wide mpv.
  postInstall = ''
    wrapProgram $out/bin/poolside --prefix PATH : ${lib.makeBinPath [ mpv ]}
  '';

  meta = {
    description = "Retro TUI streamer for Poolside FM (radio.co station sc9cb59935)";
    mainProgram = "poolside";
  };
}
