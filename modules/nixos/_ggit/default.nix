{ buildGoModule, git }:
buildGoModule {
  pname = "ggit";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-bPJUKyJiagqDgs6PEu9NajmaIfmClICLRt+qq19Upb4=";

  # The web handler tests shell out to git to build their fixture repos.
  nativeCheckInputs = [ git ];

  meta.mainProgram = "ggit";
}
