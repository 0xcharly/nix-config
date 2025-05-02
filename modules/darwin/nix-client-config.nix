{
  nix.settings = {
    allowed-users = ["@admin"];
    trusted-users = ["@wheel" "root"];
  };
}
