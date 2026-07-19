{
  lib,
  rustPlatform,
  fetchFromGitea,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cfait";
  version = "1.0.9";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "trougnouf";
    repo = "cfait";
    tag = "v${finalAttrs.version}";
    hash = "sha256-8wbQdCWpyzOjawdp/78cKPiBixhLfU5OBUZvKW0i6yY=";
  };

  cargoHash = "sha256-wIMrfW2atR64xUd8li+dplK1qQW2tvA+Fim9kf+xAt4=";

  # Default cargo features build only the TUI/CLI binary (`cfait`).
  # The GUI (`cfait-gui`, iced/vulkan) is deliberately not built.

  # Upstream tests spin up mock HTTP servers (mockito) and are serialized;
  # skip them in the sandbox.
  doCheck = false;

  meta = {
    description = "Powerful, fast and elegant CalDAV task/TODO manager (TUI & CLI)";
    homepage = "https://codeberg.org/trougnouf/cfait";
    license = lib.licenses.gpl3Plus;
    mainProgram = "cfait";
  };
})
