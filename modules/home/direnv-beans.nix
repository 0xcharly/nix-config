{config, ...}: {
  programs.direnv.config.whitelist.prefix = [
    "${config.home.homeDirectory}/beans"
  ];
}
