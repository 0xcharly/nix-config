{
  perSystem = {pkgs, ...}: {
    apps = {
      prefetch-url-sha256 = import ./prefetch-url-sha256 {inherit pkgs;};
    };
  };
}
