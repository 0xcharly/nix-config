{ buildGoModule, git }:
buildGoModule {
  pname = "ggit";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-CVycV7wxo7nOHm7qjZKfJrIkNcIApUNzN1mSIIwQN0g=";

  # The web handler tests shell out to git to build their fixture repos.
  nativeCheckInputs = [ git ];

  meta.mainProgram = "ggit";
}
