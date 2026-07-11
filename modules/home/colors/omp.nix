# Theme for the Oh My Pi coding agent (omp).
# Token reference: https://github.com/can1357/oh-my-pi/blob/main/docs/theme.md
# omp loads custom themes from ~/.omp/agent/themes/<name>.json and validates
# that every `colors` token below is present.
{ self, ... }:
let
  inherit (self.lib.colors) name;
  colors = self.lib.colors.asHexStrings;
in
{
  flake.homeModules.colors-omp = {
    home.file.".omp/agent/themes/${name}.json".text = builtins.toJSON {
      inherit name;
      colors = with colors; {
        # Core text and borders
        inherit accent text;
        border = borders;
        borderAccent = borders_accent;
        borderMuted = borders_inactive;
        success = text_ok;
        error = text_error;
        warning = text_warning;
        muted = text_dim;
        dim = text_dimmer;
        thinkingText = text_variant_dim;

        # Background blocks
        selectedBg = surface_cursorline;
        userMessageBg = surface_blue;
        customMessageBg = surface_purple;
        toolPendingBg = surface_cursorline;
        toolSuccessBg = surface_green;
        toolErrorBg = surface_red;
        statusLineBg = surface_statusline;

        # Message/tool text
        userMessageText = text;
        customMessageText = text;
        customMessageLabel = on_surface_purple;
        toolTitle = text_title;
        toolOutput = text_dim;

        # Markdown
        mdHeading = accent;
        mdLink = text_link;
        mdLinkUrl = text_variant_dimmer;
        mdCode = text_amber;
        mdCodeBlock = text;
        mdCodeBlockBorder = borders_focused_inactive;
        mdQuote = text_variant_dim;
        mdQuoteBorder = text_variant_dimmer;
        mdHr = borders;
        mdListBullet = accent;

        # Tool diff
        toolDiffAdded = text_green;
        toolDiffRemoved = text_red;
        toolDiffContext = text_dimmer;

        # Syntax highlighting: mirrors the nvim colorscheme's role mapping
        # (modules/home/vimPlugins/_splicedpixel-nvim/plugin/init.lua).
        syntaxComment = text_comment;
        syntaxKeyword = text_variant;
        syntaxFunction = text_function;
        syntaxVariable = text;
        syntaxString = text_green;
        syntaxNumber = text_orange;
        syntaxType = text_emerald;
        syntaxOperator = text_dimmer;
        syntaxPunctuation = text_dimmer;

        # Mode/thinking borders
        thinkingOff = text_dimmest;
        thinkingMinimal = text_dim;
        thinkingLow = text_blue;
        thinkingMedium = text_cyan;
        thinkingHigh = text_violet;
        thinkingXhigh = text_red;
        bashMode = text_green;
        pythonMode = text_yellow;

        # Status line segments
        statusLineSep = on_surface_statusline_dimmest;
        statusLineModel = accent;
        statusLinePath = text_blue;
        statusLineGitClean = text_green;
        statusLineGitDirty = text_amber;
        statusLineContext = text_cyan;
        statusLineSpend = text_sky;
        statusLineStaged = text_green;
        statusLineDirty = text_amber;
        statusLineUntracked = text_red;
        statusLineOutput = on_surface_statusline;
        statusLineCost = accent_dark;
        statusLineSubagents = text_violet;
      };
      export = with colors; {
        pageBg = shell_surface;
        cardBg = surface;
        infoBg = surface_cursorline;
      };
    };
  };
}
