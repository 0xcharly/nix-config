{buildGoModule}:
buildGoModule {
  pname = "caddy";
  version = "2.10.0-20250713";
  src = ./src;
  runVend = true;
  vendorHash = "sha256-lT1k+EgvzZtX1TwtYuYHdoHliN8VGPgD1zkM45k8dHI=";

  meta = {
    mainProgram = "caddy";
  };
}
