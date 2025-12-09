{config, ...}: {
  # TODO(25.11): Deprecated config: ui.diff.tool is renamed to ui.diff-formatter
  programs.jujutsu.settings.ui.diff.tool = config.programs.jujutsu.settings.ui.diff-formatter;
}
