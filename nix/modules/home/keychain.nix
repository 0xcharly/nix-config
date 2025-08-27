{
  programs.keychain = {
    enable = true;
    enableFishIntegration = true;
    keys = []; # Clear ["id_rsa"] default.
  };
}
