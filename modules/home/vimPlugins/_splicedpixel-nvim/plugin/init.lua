local T = require('splicedpixel.palette')

-- Terminal groups {{{

vim.g.terminal_color_0 = T.terminal_color_0
vim.g.terminal_color_8 = T.terminal_color_8

vim.g.terminal_color_1 = T.terminal_color_1
vim.g.terminal_color_9 = T.terminal_color_9

vim.g.terminal_color_2 = T.terminal_color_2
vim.g.terminal_color_10 = T.terminal_color_10

vim.g.terminal_color_3 = T.terminal_color_3
vim.g.terminal_color_11 = T.terminal_color_11

vim.g.terminal_color_4 = T.terminal_color_4
vim.g.terminal_color_12 = T.terminal_color_12

vim.g.terminal_color_5 = T.terminal_color_5
vim.g.terminal_color_13 = T.terminal_color_13

vim.g.terminal_color_6 = T.terminal_color_6
vim.g.terminal_color_14 = T.terminal_color_14

vim.g.terminal_color_7 = T.terminal_color_7
vim.g.terminal_color_15 = T.terminal_color_15

--- }}}

---@param groups {[string]: table}
local function load_colorscheme(groups)
  if type(groups) ~= 'table' then
    error('generate_colorscheme: invalid parameter: expected a table, got ' .. type(groups))
  end

  for group, setting in pairs(groups) do
    vim.api.nvim_set_hl(0, group, setting)
  end
end

load_colorscheme {

  -- Editor {{{

  ColorColumn = { bg = T.surface_amber }, -- used for the columns set with 'colorcolumn'
  Conceal = { fg = T.text_variant_conceal }, -- placeholder characters substituted for concealed text (see 'conceallevel')
  Cursor = { fg = T.on_surface_cursor, bg = T.surface_cursor, reverse = true }, -- character under the cursor
  lCursor = { link = 'Cursor' }, -- the character under the cursor when |language-mapping| is used (see 'guicursor')
  CursorIM = { link = 'Cursor' }, -- like Cursor, but used when in IME mode |CursorIM|
  CursorColumn = { link = 'CursorLine' },
  CursorLine = { bg = T.surface_cursorline },
  Directory = { fg = T.text_blue }, -- directory names (and other special names in listings)
  EndOfBuffer = { fg = T.text_conceal }, -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
  ErrorMsg = { fg = T.text_error }, -- error messages on the command line
  VertSplit = { fg = T.surface }, -- the column separating vertically split windows
  Folded = { fg = T.on_surface_blue, bg = T.surface_blue }, -- line used for closed folds
  FoldColumn = { fg = T.text_variant_dimmer }, -- 'foldcolumn'
  SignColumn = { fg = T.text_variant_dim }, -- column where |signs| are displayed
  SignColumnSB = { fg = T.text_variant_dim, bg = T.surface }, -- column where |signs| are displayed
  Substitute = { fg = T.on_surface_green, bg = T.surface_green }, -- |:substitute| replacement text highlighting
  LineNr = { fg = T.text_lineno }, -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
  CursorLineNr = { fg = T.text_lineno_cursor }, -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line. highlights the number in numberline.
  MatchParen = { fg = T.UNUSED, bg = T.UNUSED }, -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
  ModeMsg = { fg = T.text }, -- 'showmode' message (e.g., "-- INSERT -- ")
  -- MsgArea = { fg = T.UNUSED }, -- Area for messages and cmdline, don't set this highlight because of https://github.com/neovim/neovim/issues/17832
  MsgSeparator = { link = 'WinSeparator' }, -- Separator for scrolled messages, `msgsep` flag of 'display'
  MoreMsg = { fg = T.text_blue }, -- |more-prompt|
  NonText = { link = 'Conceal' }, -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
  Normal = { fg = T.text, bg = T.surface },
  NormalNC = { link = 'Normal' }, -- normal text in non-current windows
  NormalSB = { link = 'Normal' }, -- normal text in non-current windows
  NormalFloat = { link = 'Normal' }, -- normal text in floating windows
  FloatBorder = { fg = T.borders, bg = 'NONE' },
  FloatTitle = { link = 'Title' }, -- Title of floating windows
  FloatShadow = { fg = 'NONE' },
  Pmenu = { fg = T.text, bg = T.surface_menu }, -- Popup menu: normal item.
  PmenuSel = { bg = T.surface_menu_cursorline }, -- Popup menu: selected item.
  PmenuMatch = { fg = T.text, bold = true }, -- Popup menu: matching text.
  PmenuMatchSel = { bold = true }, -- Popup menu: matching text in selected item; is combined with |hl-PmenuMatch| and |hl-PmenuSel|.
  PmenuSbar = { bg = T.surface_scrollbar }, -- Popup menu: scrollbar.
  PmenuThumb = { bg = T.surface_scrollbar_thumb }, -- Popup menu: Thumb of the scrollbar.
  PmenuExtra = { fg = T.text_dim }, -- Popup menu: normal item extra text.
  PmenuExtraSel = { fg = T.text_dim, bg = T.surface_menu_cursorline, bold = true }, -- Popup menu: selected item extra text.
  ComplMatchIns = { link = 'PreInsert' }, -- Matched text of the currently inserted completion.
  PreInsert = { fg = T.text_dimmer }, -- Text inserted when "preinsert" is in 'completeopt'.
  ComplHint = { fg = T.text_dim }, -- Virtual text of the currently selected completion.
  ComplHintMore = { link = 'Question' }, -- The additional information of the virtual text.
  Question = { fg = T.text_blue }, -- |hit-enter| prompt and yes/no questions
  QuickFixLine = { bold = true }, -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
  Search = { fg = T.on_surface_search, bg = T.surface_search }, -- Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
  IncSearch = { link = 'Search' }, -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
  CurSearch = { fg = T.on_surface_search, bg = T.surface_search, standout = true }, -- 'cursearch' highlighting: highlights the current search you're on differently
  SpecialKey = { link = 'NonText' }, -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' textspace. |hl-Whitespace|
  SpellBad = { sp = T.text_red, undercurl = true }, -- Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.
  SpellCap = { sp = T.text_yellow, undercurl = true }, -- Word that should start with a capital. |spell| Combined with the highlighting used otherwise.
  SpellLocal = { sp = T.text_blue, undercurl = true }, -- Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.
  SpellRare = { sp = T.text_green, undercurl = true }, -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.
  StatusLine = { fg = T.on_surface_statusline, bg = T.surface_statusline }, -- status line of current window
  StatusLineNC = { link = 'StatusLine' }, -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
  TabLine = { fg = T.text_dimmer, bg = T.surface }, -- tab pages line, not active tab page label
  TabLineFill = { link = 'TabLine' }, -- tab pages line, where there are no labels
  TabLineSel = { fg = T.text, bg = T.surface, bold = true }, -- tab pages line, active tab page label
  TermCursor = { link = 'Cursor' }, -- cursor in a focused terminal
  TermCursorNC = { link = 'Cursor' }, -- cursor in unfocused terminals
  Title = { fg = T.text_title, bold = true },
  Visual = { fg = T.on_surface_visual, bg = T.surface_visual },
  VisualNOS = { link = 'Visual' },
  WarningMsg = { fg = T.text_yellow }, -- warning messages
  Whitespace = { link = 'Conceal' }, -- "nbsp", "space", "tab" and "trail" in 'listchars'
  WildMenu = { bg = T.UNUSED }, -- current match in 'wildmenu' completion
  WinBar = { fg = T.UNUSED },
  WinBarNC = { link = 'WinBar' },
  WinSeparator = { fg = T.text_variant_conceal },

  -- }}}
  -- Syntax {{{

  Punctuation = { fg = T.text_dimmer },

  Comment = { fg = T.text_comment },
  SpecialComment = { link = 'Special' }, -- special things inside a comment
  Constant = { fg = T.text_orange }, -- (preferred) any constant
  String = { fg = T.text_green }, -- a string constant: "this is a string"
  Character = { fg = T.text_teal }, --  a character constant: 'c', '\n'
  Number = { link = 'Constant' }, --   a number constant: 234, 0xff
  Float = { link = 'Number' }, -- a floating point constant: 2.3e10
  Boolean = { link = 'Constant' }, -- a boolean constant: TRUE, false
  Identifier = { fg = T.text }, -- (preferred) any variable name
  Function = { fg = T.text_blue }, -- function name (also: methods for classes)
  Statement = { link = 'Keyword' }, -- (preferred) any statement; matches treesitter's @keyword family
  Conditional = { fg = T.text_indigo }, --  if, then, else, endif, switch, etc.
  Repeat = { link = 'Conditional' }, --   for, do, while, etc.
  Label = { fg = T.text_sky }, --    case, default, etc.
  Operator = { link = 'Punctuation' }, -- "sizeof", "+", "*", etc.
  Keyword = { fg = T.text_variant, bold = true }, --  any other keyword
  Exception = { link = 'Statement' }, --  try, catch, throw

  PreProc = { fg = T.text_pink }, -- (preferred) generic Preprocessor
  Include = { fg = T.text_indigo }, --  preprocessor #include
  Define = { link = 'PreProc' }, -- preprocessor #define
  Macro = { fg = T.text_indigo }, -- same as Define
  PreCondit = { link = 'PreProc' }, -- preprocessor #if, #else, #endif, etc.

  StorageClass = { link = 'Keyword' }, -- static, register, volatile, etc.; treesitter maps these to @keyword.modifier -> Keyword
  Structure = { link = 'Keyword' }, --  struct, union, enum, etc.; treesitter maps these to @keyword.type -> Keyword
  Special = { fg = T.text_pink }, -- (preferred) any special symbol
  Type = { fg = T.text_emerald }, -- (preferred) int, long, char, etc.
  Typedef = { link = 'Keyword' }, --  A typedef; treesitter maps the keyword to @keyword.type -> Keyword
  SpecialChar = { link = 'Special' }, -- special character in a constant
  Tag = { fg = T.text_purple, bold = true }, -- you can use CTRL-] on this
  Delimiter = { link = 'Punctuation' }, -- character that needs attention
  Debug = { link = 'Special' }, -- debugging statements

  Underlined = { underline = true }, -- (preferred) text that stands out, HTML links
  Bold = { bold = true },
  Italic = { italic = true },
  -- ("Ignore", below, may be invisible…)
  -- Ignore = { }, -- (preferred) left blank, hidden  |hl-Ignore|

  Error = { fg = T.text_error }, -- (preferred) any erroneous construct
  Todo = { fg = T.text_sky, bold = true }, -- (preferred) anything that needs extra attention; mostly the keywords TODO FIXME and XXX
  qfLineNr = { fg = T.text_amber },
  qfFileName = { fg = T.text_blue },
  htmlH1 = { fg = T.text_pink, bold = true },
  htmlH2 = { fg = T.text_blue, bold = true },
  mkdHeading = { fg = T.text, bold = true },
  mkdCode = { fg = T.text, bg = T.surface_dark },
  mkdCodeDelimiter = { fg = T.text, bg = T.surface },
  mkdCodeStart = { fg = T.text_pink, bold = true },
  mkdCodeEnd = { fg = T.text_pink, bold = true },
  mkdLink = { fg = T.text_link, underline = true },

  -- diff
  Added = { fg = T.text_green },
  Changed = { fg = T.text_blue },
  diffAdded = { fg = T.text_green },
  diffRemoved = { fg = T.text_red },
  diffChanged = { fg = T.text_blue },
  diffOldFile = { fg = T.text_amber },
  diffNewFile = { fg = T.text_orange },
  diffFile = { fg = T.text_blue },
  diffLine = { fg = T.surface },
  diffIndexLine = { fg = T.text_teal },
  DiffAdd = { bg = T.surface_green }, -- diff mode: Added line |diff.txt|
  DiffChange = { bg = T.surface_blue }, -- diff mode: Changed line |diff.txt|
  DiffDelete = { bg = T.surface_red }, -- diff mode: Deleted line |diff.txt|
  DiffText = { bg = T.surface_violet }, -- diff mode: Changed text within a changed line |diff.txt|

  -- NeoVim
  healthError = { fg = T.text_error },
  healthSuccess = { fg = T.text_ok },
  healthWarning = { fg = T.text_warning },

  -- rainbow
  rainbow1 = { fg = T.text_red },
  rainbow2 = { fg = T.text_orange },
  rainbow3 = { fg = T.text_yellow },
  rainbow4 = { fg = T.text_green },
  rainbow5 = { fg = T.text_sky },
  rainbow6 = { fg = T.text_violet },

  -- markdown
  markdownHeadingDelimiter = { fg = T.text_orange, bold = true },
  markdownCode = { fg = T.text_rose },
  markdownCodeBlock = { fg = T.text_rose },
  markdownLinkText = { fg = T.text_link, underline = true },
  markdownH1 = { link = 'rainbow1' },
  markdownH2 = { link = 'rainbow2' },
  markdownH3 = { link = 'rainbow3' },
  markdownH4 = { link = 'rainbow4' },
  markdownH5 = { link = 'rainbow5' },
  markdownH6 = { link = 'rainbow6' },

  -- }}}
  -- Diagnostics and LSP {{{

  LspReferenceText = { bg = T.surface_menu }, -- used for highlighting "text" references
  LspReferenceRead = { bg = T.surface_menu }, -- used for highlighting "read" references
  LspReferenceWrite = { bg = T.surface_menu }, -- used for highlighting "write" references
  LspSignatureActiveParameter = { fg = T.text_indigo, bold = true },
  LspCodeLens = { fg = T.text_variant_dimmer }, -- virtual text of the codelens
  LspCodeLensSeparator = { link = 'LspCodeLens' }, -- virtual text of the codelens separators
  -- fg of `Comment` and bg of `CursorLine`.
  LspInlayHint = { fg = T.text_variant_dimmer, bg = T.surface_cursorline }, -- virtual text of the inlay hints
  LspInfoBorder = { link = 'FloatBorder' },

  DiagnosticOk = { fg = T.text_ok },
  DiagnosticHint = { fg = T.text_hint },
  DiagnosticInfo = { fg = T.text_info },
  DiagnosticWarn = { fg = T.text_warning },
  DiagnosticError = { fg = T.text_error },
  DiagnosticFloatingOk = { link = 'DiagnosticOk' }, -- Used to color diagnostic messages in diagnostics float
  DiagnosticFloatingHint = { link = 'DiagnosticHint' },
  DiagnosticFloatingInfo = { link = 'DiagnosticInfo' },
  DiagnosticFloatingWarn = { link = 'DiagnosticWarn' },
  DiagnosticFloatingError = { link = 'DiagnosticError' },
  DiagnosticSignOk = { link = 'DiagnosticOk' }, -- Used for signs in sign column
  DiagnosticSignHint = { link = 'DiagnosticHint' },
  DiagnosticSignInfo = { link = 'DiagnosticInfo' },
  DiagnosticSignWarn = { link = 'DiagnosticWarn' },
  DiagnosticSignError = { link = 'DiagnosticError' },
  DiagnosticUnderlineOk = { sp = T.text_ok, undercurl = true }, -- Used to underline diagnostics
  DiagnosticUnderlineHint = { sp = T.text_hint, undercurl = true },
  DiagnosticUnderlineInfo = { sp = T.text_info, undercurl = true },
  DiagnosticUnderlineWarn = { sp = T.text_warning, undercurl = true },
  DiagnosticUnderlineError = { sp = T.text_error, undercurl = true },
  DiagnosticVirtualTextOk = { fg = T.on_surface_green, bg = T.surface_green }, -- Used as the mantle highlight group. Other Diagnostic highlights link to this by default
  DiagnosticVirtualTextHint = { fg = T.on_surface_violet, bg = T.surface_violet },
  DiagnosticVirtualTextInfo = { fg = T.on_surface_blue, bg = T.surface_blue },
  DiagnosticVirtualTextWarn = { fg = T.on_surface_amber, bg = T.surface_amber },
  DiagnosticVirtualTextError = { fg = T.on_surface_red, bg = T.surface_red },

  LspDiagnosticsHint = { link = 'DiagnosticHint' },
  LspDiagnosticsInformation = { link = 'DiagnosticInfo' },
  LspDiagnosticsWarning = { link = 'DiagnosticWarn' },
  LspDiagnosticsError = { link = 'DiagnosticError' },
  LspDiagnosticsDefaultHint = { link = 'DiagnosticHint' }, -- Used as the mantle highlight group. Other LspDiagnostic highlights link to this by default (except Underline)
  LspDiagnosticsDefaultInformation = { link = 'DiagnosticInfo' },
  LspDiagnosticsDefaultWarning = { link = 'DiagnosticWarn' },
  LspDiagnosticsDefaultError = { link = 'DiagnosticError' },
  LspDiagnosticsVirtualTextHint = { link = 'DiagnosticVirtualTextHint' }, -- Used for diagnostic virtual text
  LspDiagnosticsVirtualTextInformation = { link = 'DiagnosticVirtualTextInfo' },
  LspDiagnosticsVirtualTextWarning = { link = 'DiagnosticVirtualTextWarn' },
  LspDiagnosticsVirtualTextError = { link = 'DiagnosticVirtualTextError' },

  -- }}}
  -- Treesitter {{{

  -- Identifiers
  ['@variable'] = { fg = T.text }, -- Any variable name that does not have another highlight.
  ['@variable.builtin'] = { fg = T.text_purple }, -- Variable names that are defined by the languages, like this or self.
  ['@variable.parameter'] = { fg = T.text_pink, italic = true }, -- For parameters of a function. Declaration only: highlights.scm captures the signature; usages in the body are plain @variable (LSP semantic tokens, which would repaint usages, are disabled globally in plugin/lsp.lua).
  ['@variable.member'] = { link = '@property' }, -- For fields: same concept as @property; one color (blue) for both.

  ['@constant'] = { link = 'Constant' }, -- For constants
  ['@constant.builtin'] = { fg = T.text_orange }, -- For constant that are built in the language: nil in Lua.
  ['@constant.macro'] = { link = 'Macro' }, -- For constants that are defined by macros: NULL in C.

  ['@module'] = { fg = T.text_amber, italic = true }, -- For identifiers referring to modules and namespaces.
  ['@label'] = { link = 'Label' }, -- For labels: label: in C and :label: in Lua.

  -- Literals
  ['@string'] = { link = 'String' }, -- For strings.
  ['@string.documentation'] = { fg = T.text_teal }, -- For strings documenting code (e.g. Python docstrings).
  ['@string.regexp'] = { fg = T.text_pink }, -- For regexes.
  ['@string.escape'] = { fg = T.text_pink }, -- For escape characters within a string.
  ['@string.special'] = { link = 'Special' }, -- other special strings (e.g. dates)
  ['@string.special.path'] = { link = 'Special' }, -- filenames
  ['@string.special.symbol'] = { fg = T.text_pink }, -- symbols or atoms
  ['@string.special.url'] = { fg = T.text_link, italic = true, underline = true }, -- urls, links and emails
  ['@punctuation.delimiter.regex'] = { link = '@string.regexp' },

  ['@character'] = { link = 'Character' }, -- character literals
  ['@character.special'] = { link = 'SpecialChar' }, -- special characters (e.g. wildcards)

  ['@boolean'] = { link = 'Boolean' }, -- For booleans.
  ['@number'] = { link = 'Number' }, -- For all numbers
  ['@number.float'] = { link = 'Float' }, -- For floats.

  -- Types
  ['@type'] = { link = 'Type' }, -- For types.
  ['@type.builtin'] = { fg = T.text_purple, italic = true }, -- For builtin types.
  ['@type.definition'] = { link = 'Type' }, -- type definitions (e.g. `typedef` in C)

  ['@attribute'] = { link = 'Constant' }, -- attribute annotations (e.g. Python decorators)
  ['@property'] = { fg = T.text_blue }, -- For fields, like accessing `bar` property on `foo.bar`. Overriden later for CSS.

  -- Functions
  ['@function'] = { link = 'Function' }, -- For function (calls and definitions).
  ['@function.builtin'] = { fg = T.text_orange }, -- For builtin functions: table.insert in Lua.
  ['@function.call'] = { fg = T.text, bold = true }, -- function calls: bold plain text, mimicking fish_color_command; only definitions carry the function color.
  ['@function.macro'] = { link = 'Macro' }, -- For macro defined functions (calls and definitions): each macro_rules in Rust.

  ['@function.method'] = { link = 'Function' }, -- For method definitions.
  ['@function.method.call'] = { fg = T.text, bold = true }, -- method calls: bold plain, like @function.call.

  ['@constructor'] = { fg = T.text_amber }, -- For constructor calls and definitions: = { } in Lua, and Java constructors.
  ['@operator'] = { link = 'Operator' }, -- For any operator: +, but also -> and * in C.

  -- Keywords
  ['@keyword'] = { link = 'Keyword' }, -- For keywords that don't fall in previous categories.
  ['@keyword.modifier'] = { link = 'Keyword' }, -- For keywords modifying other constructs (e.g. `const`, `static`, `public`)
  ['@keyword.type'] = { link = 'Keyword' }, -- For keywords describing composite types (e.g. `struct`, `enum`)
  ['@keyword.coroutine'] = { link = 'Keyword' }, -- For keywords related to coroutines (e.g. `go` in Go, `async/await` in Python)
  ['@keyword.function'] = { fg = T.text_indigo }, -- For keywords used to define a function.
  ['@keyword.operator'] = { fg = T.text_indigo }, -- For new keyword operator
  ['@keyword.import'] = { link = 'Include' }, -- For includes: #include in C, use or extern crate in Rust, or require in Lua.
  ['@keyword.repeat'] = { link = 'Repeat' }, -- For keywords related to loops.
  ['@keyword.return'] = { fg = T.text_indigo },
  ['@keyword.debug'] = { link = 'Exception' }, -- For keywords related to debugging
  ['@keyword.exception'] = { link = 'Exception' }, -- For exception related keywords.

  ['@keyword.conditional'] = { link = 'Conditional' }, -- For keywords related to conditionnals.
  ['@keyword.conditional.ternary'] = { link = 'Operator' }, -- For ternary operators (e.g. `?` / `:`)

  ['@keyword.directive'] = { link = 'PreProc' }, -- various preprocessor directives & shebangs
  ['@keyword.directive.define'] = { link = 'Define' }, -- preprocessor definition directives
  ['@keyword.export'] = { fg = T.text_indigo }, -- JS & derivative

  -- Punctuation
  ['@punctuation.delimiter'] = { link = 'Delimiter' }, -- For delimiters (e.g. `;` / `.` / `,`).
  ['@punctuation.bracket'] = { link = 'Punctuation' }, -- For brackets and parenthesis.
  ['@punctuation.special'] = { link = 'Special' }, -- For special punctuation that does not fall in the categories before (e.g. `{}` in string interpolation).

  -- Comment
  ['@comment'] = { link = 'Comment' },
  ['@comment.documentation'] = { link = 'Comment' }, -- For comments documenting code

  ['@comment.error'] = { fg = T.text_error, bold = true },
  ['@comment.warning'] = { fg = T.text_warning, bold = true },
  ['@comment.hint'] = { fg = T.text_hint, bold = true },
  ['@comment.todo'] = { fg = T.text_info, bold = true },
  ['@comment.note'] = { link = 'Title' },

  -- Markup
  ['@markup'] = { fg = T.text }, -- For strings considerated text in a markup language.
  ['@markup.strong'] = { link = 'Bold' }, -- bold
  ['@markup.italic'] = { link = 'Italic' }, -- italic
  ['@markup.strikethrough'] = { strikethrough = true }, -- strikethrough text
  ['@markup.underline'] = { link = 'Underlined' }, -- underlined text

  ['@markup.heading'] = { link = 'Title' }, -- titles like: # Example
  ['@markup.heading.markdown'] = { bold = true }, -- bold headings in markdown, but not in HTML or other markup

  -- ['@markup.math'] = { fg = C.blue }, -- math environments (e.g. `$ ... $` in LaTeX)
  -- ['@markup.quote'] = { fg = C.pink }, -- block quotes
  -- ['@markup.environment'] = { fg = C.pink }, -- text environments of markup languages
  -- ['@markup.environment.name'] = { fg = C.blue }, -- text indicating the type of an environment

  ['@markup.link'] = { fg = T.text_link, underline = true }, -- text references, footnotes, citations, etc.
  ['@markup.link.label'] = { link = '@markup.link' }, -- link, reference descriptions
  ['@markup.link.url'] = { link = '@markup.link' }, -- urls, links and emails

  ['@markup.raw'] = { fg = T.text_green }, -- used for inline code in markdown and for doc in python (""")

  ['@markup.list'] = { fg = T.text_teal },
  ['@markup.list.checked'] = { fg = T.text_green }, -- todo notes
  ['@markup.list.unchecked'] = { fg = T.text_dim }, -- todo notes

  -- Diff
  ['@diff.plus'] = { link = 'diffAdded' }, -- added text (for diff files)
  ['@diff.minus'] = { link = 'diffRemoved' }, -- deleted text (for diff files)
  ['@diff.delta'] = { link = 'diffChanged' }, -- deleted text (for diff files)

  -- Tags
  ['@tag'] = { fg = T.text_blue }, -- Tags like HTML tag names.
  ['@tag.builtin'] = { fg = T.text_blue }, -- JSX tag names.
  ['@tag.attribute'] = { fg = T.text_amber, italic = true }, -- XML/HTML attributes (foo in foo="bar").
  ['@tag.delimiter'] = { fg = T.text_teal }, -- Tag delimiter like < > /

  -- Misc
  ['@error'] = { link = 'Error' },

  -- Language specific {{{

  -- markdown
  ['@markup.heading.1.markdown'] = { link = 'markdownH1' },
  ['@markup.heading.2.markdown'] = { link = 'markdownH2' },
  ['@markup.heading.3.markdown'] = { link = 'markdownH3' },
  ['@markup.heading.4.markdown'] = { link = 'markdownH4' },
  ['@markup.heading.5.markdown'] = { link = 'markdownH5' },
  ['@markup.heading.6.markdown'] = { link = 'markdownH6' },

  -- html
  ['@markup.heading.html'] = { link = '@markup' },
  ['@markup.heading.1.html'] = { link = '@markup' },
  ['@markup.heading.2.html'] = { link = '@markup' },
  ['@markup.heading.3.html'] = { link = '@markup' },
  ['@markup.heading.4.html'] = { link = '@markup' },
  ['@markup.heading.5.html'] = { link = '@markup' },
  ['@markup.heading.6.html'] = { link = '@markup' },

  ['@string.special.url.html'] = { fg = T.text_green }, -- Links in href, src attributes.
  ['@markup.link.label.html'] = { fg = T.text }, -- Text between <a></a> tags.
  ['@character.special.html'] = { fg = T.text_red }, -- Symbols such as &nbsp;.

  -- CSS
  ['@property.css'] = { fg = T.text_blue },
  ['@property.scss'] = { fg = T.text_blue },
  ['@property.id.css'] = { fg = T.text_amber },
  ['@property.class.css'] = { fg = T.text_amber },
  ['@type.css'] = { fg = T.text_indigo },
  ['@type.tag.css'] = { fg = T.text_blue },
  ['@string.plain.css'] = { fg = T.text },
  ['@keyword.directive.css'] = { link = 'Keyword' }, -- CSS at-rules: https://developer.mozilla.org/en-US/docs/Web/CSS/At-rule.

  -- Beancount
  ['@type.beancount'] = { link = 'Normal' }, -- Beancount's accounts.

  -- Lua
  ['@constructor.lua'] = { link = '@punctuation.bracket' }, -- For constructor calls and definitions: = { } in Lua.

  -- Python
  ['@constructor.python'] = { fg = T.text_sky }, -- __init__(), __new__().

  -- C/CPP
  ['@keyword.import.c'] = { link = 'Include' },
  ['@keyword.import.cpp'] = { link = 'Include' },

  -- gitcommit
  ['@comment.warning.gitcommit'] = { fg = T.text_warning },

  -- gitignore
  ['@string.special.path.gitignore'] = { fg = T.text },

  -- }}}
  -- }}}
  -- StatusLine {{{

  StatusLineFocusedPrimary = { fg = T.on_surface_statusline, bold = true },
  StatusLineFocusedSecondary = { fg = T.on_surface_statusline_dimmer },

  StatusLineUnfocusedPrimary = { fg = T.on_surface_statusline_dimmer, bold = true },
  StatusLineUnfocusedSecondary = { fg = T.on_surface_statusline_dimmer },

  -- }}}
  -- Cmp {{{

  CmpItemAbbr = { fg = T.text_dim },
  CmpItemAbbrDeprecated = { fg = T.text_dim, strikethrough = true },
  CmpItemKind = { fg = T.text_blue },
  CmpItemMenu = { fg = T.text },
  CmpItemAbbrMatch = { fg = T.text, bold = true },
  CmpItemAbbrMatchFuzzy = { fg = T.text, bold = true },

  -- kind support
  CmpItemKindSnippet = { fg = T.text_violet },
  CmpItemKindKeyword = { fg = T.text_red },
  CmpItemKindText = { fg = T.text_teal },
  CmpItemKindMethod = { link = 'Function' },
  CmpItemKindConstructor = { link = 'Function' },
  CmpItemKindFunction = { link = 'Function' },
  CmpItemKindFolder = { link = 'Directory' },
  CmpItemKindModule = { fg = T.text_blue },
  CmpItemKindConstant = { link = 'Constant' },
  CmpItemKindField = { fg = T.text_green },
  CmpItemKindProperty = { fg = T.text_green },
  CmpItemKindEnum = { fg = T.text_green },
  CmpItemKindUnit = { fg = T.text_green },
  CmpItemKindClass = { fg = T.text_amber },
  CmpItemKindVariable = { fg = T.text_pink },
  CmpItemKindFile = { fg = T.text_blue },
  CmpItemKindInterface = { fg = T.text_amber },
  CmpItemKindColor = { fg = T.text_red },
  CmpItemKindReference = { fg = T.text_red },
  CmpItemKindEnumMember = { fg = T.text_red },
  CmpItemKindStruct = { fg = T.text_blue },
  CmpItemKindValue = { fg = T.text_orange },
  CmpItemKindEvent = { fg = T.text_blue },
  CmpItemKindOperator = { fg = T.text_blue },
  CmpItemKindTypeParameter = { fg = T.text_blue },
  CmpItemKindCopilot = { fg = T.text_teal },

  -- }}}
  -- Noice {{{

  NoiceCmdLine = { link = 'Normal' },
  NoiceCmdlinePopupBorder = { link = 'FloatBorder' },
  NoiceCmdLineIcon = { link = 'Normal' },
  NoiceCmdlineIconCmdline = { fg = T.text_emerald },
  NoiceCmdlineIconLua = { fg = T.text_violet },
  NoiceConfirmBorder = { fg = T.text_red },

  -- }}}
  -- render markdown {{{

  RenderMarkdownH1 = { link = 'markdownH1' },
  RenderMarkdownH2 = { link = 'markdownH2' },
  RenderMarkdownH3 = { link = 'markdownH3' },
  RenderMarkdownH4 = { link = 'markdownH4' },
  RenderMarkdownH5 = { link = 'markdownH5' },
  RenderMarkdownH6 = { link = 'markdownH6' },
  RenderMarkdownCode = { bg = T.surface_dark },
  RenderMarkdownCodeInline = { bg = T.surface_dark },
  RenderMarkdownBullet = { fg = T.text_sky },
  RenderMarkdownTableHead = { fg = T.text_blue },
  RenderMarkdownTableRow = { fg = T.text_indigo },
  RenderMarkdownSuccess = { fg = T.text_ok },
  RenderMarkdownInfo = { fg = T.text_info },
  RenderMarkdownHint = { fg = T.text_hint },
  RenderMarkdownWarn = { fg = T.text_warning },
  RenderMarkdownError = { fg = T.text_error },

  -- }}}
  -- Snacks {{{

  SnacksNormal = { link = 'Normal' },
  SnacksWinBar = { link = 'Title' },
  SnacksBackdrop = { link = 'FloatShadow' },
  SnacksNormalNC = { link = 'NormalFloat' },
  SnacksWinBarNC = { link = 'SnacksWinBar' },

  SnacksNotifierInfo = { link = 'DiagnosticInfo' },
  SnacksNotifierIconInfo = { link = 'DiagnosticInfo' },
  SnacksNotifierTitleInfo = { fg = T.text_info, italic = true },
  SnacksNotifierBorderInfo = { link = 'DiagnosticInfo' },
  SnacksNotifierFooterInfo = { link = 'DiagnosticInfo' },
  SnacksNotifierWarn = { link = 'DiagnosticWarn' },
  SnacksNotifierIconWarn = { link = 'DiagnosticWarn' },
  SnacksNotifierTitleWarn = { fg = T.text_warning, italic = true },
  SnacksNotifierBorderWarn = { link = 'DiagnosticWarn' },
  SnacksNotifierFooterWarn = { link = 'DiagnosticWarn' },
  SnacksNotifierDebug = { link = 'DiagnosticHint' },
  SnacksNotifierIconDebug = { link = 'DiagnosticHint' },
  SnacksNotifierTitleDebug = { fg = T.text_hint, italic = true },
  SnacksNotifierBorderDebug = { link = 'DiagnosticHint' },
  SnacksNotifierFooterDebug = { link = 'DiagnosticHint' },
  SnacksNotifierError = { link = 'DiagnosticError' },
  SnacksNotifierIconError = { link = 'DiagnosticError' },
  SnacksNotifierTitleError = { fg = T.text_error, italic = true },
  SnacksNotifierBorderError = { link = 'DiagnosticError' },
  SnacksNotifierFooterError = { link = 'DiagnosticError' },
  SnacksNotifierTrace = { fg = T.text_fuchsia },
  SnacksNotifierIconTrace = { fg = T.text_fuchsia },
  SnacksNotifierTitleTrace = { fg = T.text_fuchsia, italic = true },
  SnacksNotifierBorderTrace = { fg = T.text_fuchsia },
  SnacksNotifierFooterTrace = { fg = T.text_fuchsia },

  SnacksDashboardNormal = { link = 'Normal' },
  SnacksDashboardDesc = { fg = T.text_blue },
  SnacksDashboardFile = { fg = T.text_indigo },
  SnacksDashboardDir = { link = 'NonText' },
  SnacksDashboardFooter = { fg = T.text_amber, italic = true },
  SnacksDashboardHeader = { fg = T.text_blue },
  SnacksDashboardIcon = { fg = T.text_pink, bold = true },
  SnacksDashboardKey = { fg = T.text_orange },
  SnacksDashboardTerminal = { link = 'SnacksDashboardNormal' },
  SnacksDashboardSpecial = { link = 'Special' },
  SnacksDashboardTitle = { link = 'Title' },

  SnacksIndent = { fg = T.surface },
  SnacksIndentScope = { fg = T.text },

  SnacksPickerSelected = { fg = T.text_pink, bg = T.surface, bold = true },
  SnacksPickerMatch = { fg = T.text_blue },

  SnacksPicker = { link = 'NormalFloat' },
  SnacksPickerBorder = { link = 'FloatBorder' },
  SnacksPickerDir = { link = 'SnacksPickerDimmed' },
  SnacksPickerDimmed = { fg = T.text_dimmer },
  SnacksPickerInputBorder = { link = 'SnacksPickerBorder' },
  SnacksPickerInput = { link = 'NormalFloat' },
  SnacksPickerPrompt = { fg = T.text_pink },
  SnacksPickerTitle = { link = 'Title' },
  SnacksPickerPreviewTitle = { link = 'SnacksPickerTitle' },
  SnacksPickerInputTitle = { link = 'SnacksPickerTitle' },
  SnacksPickerListTitle = { link = 'SnacksPickerTitle' },
  SnacksPickerInputCursorLine = { link = 'Normal' },

  -- }}}
  -- CompileMode {{{

  CompileModeError = { link = 'Error' },
  CompileModeInfo = { bold = true },
  CompileModeWarning = { link = 'WarningMsg' },
  CompileModeMessage = { link = 'Normal' },
  CompileModeMessageRow = { link = 'Normal' },
  CompileModeMessageCol = { link = 'Normal' },
  CompileModeCommandOutput = { fg = T.text_blue },
  CompileModeOutputFile = { link = 'Normal' },
  CompileModeCheckResult = { bold = true },
  CompileModeCheckTarget = { link = 'Normal' },
  CompileModeDirectoryMessage = { link = 'Normal' },
  CompileModeErrorLocus = { link = 'Normal' },

  -- }}}
}
