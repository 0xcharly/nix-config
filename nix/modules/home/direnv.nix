{config, ...}: {
  direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      warn_timeout = 0;
      whitelist.prefix = ["${config.home.homeDirectory}/code"];
    };
  };
}
