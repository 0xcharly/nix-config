{ buildGoModule }:
buildGoModule {
  pname = "splicedpixel";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-CVycV7wxo7nOHm7qjZKfJrIkNcIApUNzN1mSIIwQN0g=";

  meta.mainProgram = "splicedpixel";
}
