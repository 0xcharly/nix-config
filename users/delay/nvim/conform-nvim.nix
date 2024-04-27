{
  enable = true;
  # Install these formatters on a per-env basis (i.e. these won't be available by default on the
  # system).
  formattersByFt = {
    lua = [ "stylua" ];
    python = [ "isort" "black" ];
    "*" = [ "trim_whitespace" ];
  };
}
