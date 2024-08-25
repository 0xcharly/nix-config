{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "path-strip-prefix";
  version = "2024-08-25";

  src = ./.;

  cargoHash = "sha256-OU1FZW4bOBY4Y/I1Fe5RZ1j6BDz9I6aMwnTtx1ZAQqM=";

  meta = with lib; {
    description = "Loose equivalent of Python's `os.path.relpath` in a natively compiled binary";
    license = licenses.mit;
    maintainers = []; # TODO: setup lib.maintainers._0xcharly
    platforms = platforms.unix;
    mainProgram = "path-strip-prefix";
  };
}
