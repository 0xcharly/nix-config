# Colorscheme inspired from https://github.com/catppuccin/nvim
# MIT License: Copyright (c) 2021 Catppuccin

colors: with colors; ''
  -- Terminal groups {{{

  vim.g.terminal_color_0 = ${terminal_color_0}
  vim.g.terminal_color_8 = ${terminal_color_8}

  vim.g.terminal_color_1 = ${terminal_color_1}
  vim.g.terminal_color_9 = ${terminal_color_9}

  vim.g.terminal_color_2 = ${terminal_color_2}
  vim.g.terminal_color_10 = ${terminal_color_10}

  vim.g.terminal_color_3 = ${terminal_color_3}
  vim.g.terminal_color_11 = ${terminal_color_11}

  vim.g.terminal_color_4 = ${terminal_color_4}
  vim.g.terminal_color_12 = ${terminal_color_12}

  vim.g.terminal_color_5 = ${terminal_color_5}
  vim.g.terminal_color_13 = ${terminal_color_13}

  vim.g.terminal_color_6 = ${terminal_color_6}
  vim.g.terminal_color_14 = ${terminal_color_14}

  vim.g.terminal_color_7 = ${terminal_color_7}
  vim.g.terminal_color_15 = ${terminal_color_15}

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

    ColorColumn = { bg = ${surface_amber} }, -- used for the columns set with 'colorcolumn'
    Conceal = { fg = ${text_variant_conceal} }, -- placeholder characters substituted for concealed text (see 'conceallevel')
    Cursor = { fg = ${on_surface_cursor}, bg = ${surface_cursor}, reverse = true }, -- character under the cursor
    lCursor = { link = 'Cursor' }, -- the character under the cursor when |language-mapping| is used (see 'guicursor')
    CursorIM = { link = 'Cursor' }, -- like Cursor, but used when in IME mode |CursorIM|
    CursorColumn = { link = 'CursorLine' },
    CursorLine = { bg = ${surface_cursorline} },
    Directory = { fg = ${text_blue} }, -- directory names (and other special names in listings)
    EndOfBuffer = { fg = ${text_conceal} }, -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
    ErrorMsg = { fg = ${text_error} }, -- error messages on the command line
    VertSplit = { fg = ${surface} }, -- the column separating vertically split windows
    Folded = { fg = ${on_surface_blue}, bg = ${surface_blue} }, -- line used for closed folds
    FoldColumn = { fg = ${text_variant_dimmer} }, -- 'foldcolumn'
    SignColumn = { fg = ${text_variant_dim} }, -- column where |signs| are displayed
    SignColumnSB = { fg = ${text_variant_dim}, bg = ${surface} }, -- column where |signs| are displayed
    Substitute = { fg = ${on_surface_green}, bg = ${surface_green} }, -- |:substitute| replacement text highlighting
    LineNr = { fg = ${text_lineno} }, -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
    CursorLineNr = { fg = ${text_lineno_cursor} }, -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line. highlights the number in numberline.
    MatchParen = { fg = ${UNUSED}, bg = ${UNUSED} }, -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
    ModeMsg = { fg = ${text} }, -- 'showmode' message (e.g., "-- INSERT -- ")
    -- MsgArea = { fg = ${UNUSED} }, -- Area for messages and cmdline, don't set this highlight because of https://github.com/neovim/neovim/issues/17832
    MsgSeparator = { link = 'WinSeparator' }, -- Separator for scrolled messages, `msgsep` flag of 'display'
    MoreMsg = { fg = ${text_blue} }, -- |more-prompt|
    NonText = { link = 'Conceal' }, -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
    Normal = { fg = ${text}, bg = ${surface} },
    NormalNC = { link = 'Normal' }, -- normal text in non-current windows
    NormalSB = { link = 'Normal' }, -- normal text in non-current windows
    NormalFloat = { link = 'Normal' }, -- normal text in floating windows
    FloatBorder = { fg = ${borders}, bg = 'NONE' },
    FloatTitle = { link = 'Title' }, -- Title of floating windows
    FloatShadow = { fg = 'NONE' },
    Pmenu = { fg = ${text}, bg = ${surface_menu} }, -- Popup menu: normal item.
    PmenuSel = { bg = ${surface_menu_cursorline} }, -- Popup menu: selected item.
    PmenuMatch = { fg = ${text}, bold = true }, -- Popup menu: matching text.
    PmenuMatchSel = { bold = true }, -- Popup menu: matching text in selected item; is combined with |hl-PmenuMatch| and |hl-PmenuSel|.
    PmenuSbar = { bg = ${surface_scrollbar} }, -- Popup menu: scrollbar.
    PmenuThumb = { bg = ${surface_scrollbar_thumb} }, -- Popup menu: Thumb of the scrollbar.
    PmenuExtra = { fg = ${text_dim} }, -- Popup menu: normal item extra text.
    PmenuExtraSel = { fg = ${text_dim}, bg = ${surface_menu_cursorline}, bold = true }, -- Popup menu: selected item extra text.
    ComplMatchIns = { link = 'PreInsert' }, -- Matched text of the currently inserted completion.
    PreInsert = { fg = ${text_dimmer} }, -- Text inserted when "preinsert" is in 'completeopt'.
    ComplHint = { fg = ${text_dim} }, -- Virtual text of the currently selected completion.
    ComplHintMore = { link = 'Question' }, -- The additional information of the virtual text.
    Question = { fg = ${text_blue} }, -- |hit-enter| prompt and yes/no questions
    QuickFixLine = { bold = true }, -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    Search = { fg = ${on_surface_search}, bg = ${surface_search} }, -- Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
    IncSearch = { link = 'Search' }, -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
    CurSearch = { fg = ${on_surface_search}, bg = ${surface_search}, standout = true }, -- 'cursearch' highlighting: highlights the current search you're on differently
    SpecialKey = { link = 'NonText' }, -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' textspace. |hl-Whitespace|
    SpellBad = { sp = ${text_red}, undercurl = true }, -- Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.
    SpellCap = { sp = ${text_yellow}, undercurl = true }, -- Word that should start with a capital. |spell| Combined with the highlighting used otherwise.
    SpellLocal = { sp = ${text_blue}, undercurl = true }, -- Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.
    SpellRare = { sp = ${text_green}, undercurl = true }, -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.
    StatusLine = { fg = ${on_surface_statusline}, bg = ${surface_statusline} }, -- status line of current window
    StatusLineNC = { link = 'StatusLine' }, -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
    TabLine = { fg = ${text_dimmer}, bg = ${surface} }, -- tab pages line, not active tab page label
    TabLineFill = { link = 'TabLine' }, -- tab pages line, where there are no labels
    TabLineSel = { fg = ${text}, bg = ${surface}, bold = true }, -- tab pages line, active tab page label
    TermCursor = { link = 'Cursor' }, -- cursor in a focused terminal
    TermCursorNC = { link = 'Cursor' }, -- cursor in unfocused terminals
    Title = { fg = ${text_title}, bold = true },
    Visual = { fg = ${on_surface_visual}, bg = ${surface_visual} },
    VisualNOS = { link = 'Visual' },
    WarningMsg = { fg = ${text_yellow} }, -- warning messages
    Whitespace = { link = 'Conceal' }, -- "nbsp", "space", "tab" and "trail" in 'listchars'
    WildMenu = { bg = ${UNUSED} }, -- current match in 'wildmenu' completion
    WinBar = { fg = ${UNUSED} },
    WinBarNC = { link = 'WinBar' },
    WinSeparator = { fg = ${text_variant_conceal} },

    -- }}}
    -- Syntax {{{

    Punctuation = { fg = ${text_dimmer} },

    Comment = { fg = ${text_comment} },
    SpecialComment = { link = 'Special' }, -- special things inside a comment
    Constant = { fg = ${text_orange} }, -- (preferred) any constant
    String = { fg = ${text_green} }, -- a string constant: "this is a string"
    Character = { fg = ${text_teal} }, --  a character constant: 'c', '\n'
    Number = { fg = ${text_red} }, --   a number constant: 234, 0xff
    Float = { link = 'Number' }, -- a floating point constant: 2.3e10
    Boolean = { fg = ${text_cyan} }, -- a boolean constant: TRUE, false
    Identifier = { fg = ${text} }, -- (preferred) any variable name
    Function = { fg = ${text_function} }, -- function name (also: methods for classes)
    Statement = { link = 'Keyword' }, -- (preferred) any statement; matches treesitter's @keyword family
    Conditional = { fg = ${text_indigo} }, --  if, then, else, endif, switch, etc.
    Repeat = { link = 'Conditional' }, --   for, do, while, etc.
    Label = { fg = ${text_sky} }, --    case, default, etc.
    Operator = { link = 'Punctuation' }, -- "sizeof", "+", "*", etc.
    Keyword = { fg = ${text_variant}, bold = true }, --  any other keyword
    Exception = { link = 'Statement' }, --  try, catch, throw

    PreProc = { fg = ${text_pink} }, -- (preferred) generic Preprocessor
    Include = { fg = ${text_indigo} }, --  preprocessor #include
    Define = { link = 'PreProc' }, -- preprocessor #define
    Macro = { fg = ${text_indigo} }, -- same as Define
    PreCondit = { link = 'PreProc' }, -- preprocessor #if, #else, #endif, etc.

    StorageClass = { link = 'Keyword' }, -- static, register, volatile, etc.; treesitter maps these to @keyword.modifier -> Keyword
    Structure = { link = 'Keyword' }, --  struct, union, enum, etc.; treesitter maps these to @keyword.type -> Keyword
    Special = { fg = ${text_pink} }, -- (preferred) any special symbol
    Type = { fg = ${text_emerald} }, -- (preferred) int, long, char, etc.
    Typedef = { link = 'Keyword' }, --  A typedef; treesitter maps the keyword to @keyword.type -> Keyword
    SpecialChar = { link = 'Special' }, -- special character in a constant
    Tag = { fg = ${text_purple}, bold = true }, -- you can use CTRL-] on this
    Delimiter = { link = 'Punctuation' }, -- character that needs attention
    Debug = { link = 'Special' }, -- debugging statements

    Underlined = { underline = true }, -- (preferred) text that stands out, HTML links
    Bold = { bold = true },
    Italic = { italic = true },
    -- ("Ignore", below, may be invisible…)
    -- Ignore = { }, -- (preferred) left blank, hidden  |hl-Ignore|

    Error = { fg = ${text_error} }, -- (preferred) any erroneous construct
    Todo = { fg = ${text_sky}, bold = true }, -- (preferred) anything that needs extra attention; mostly the keywords TODO FIXME and XXX
    qfLineNr = { fg = ${text_amber} },
    qfFileName = { fg = ${text_blue} },
    htmlH1 = { fg = ${text_pink}, bold = true },
    htmlH2 = { fg = ${text_blue}, bold = true },
    mkdHeading = { fg = ${text}, bold = true },
    mkdCode = { fg = ${text}, bg = ${surface_dark} },
    mkdCodeDelimiter = { fg = ${text}, bg = ${surface} },
    mkdCodeStart = { fg = ${text_pink}, bold = true },
    mkdCodeEnd = { fg = ${text_pink}, bold = true },
    mkdLink = { fg = ${text_link}, underline = true },

    -- diff
    Added = { fg = ${text_green} },
    Changed = { fg = ${text_blue} },
    diffAdded = { fg = ${text_green} },
    diffRemoved = { fg = ${text_red} },
    diffChanged = { fg = ${text_blue} },
    diffOldFile = { fg = ${text_amber} },
    diffNewFile = { fg = ${text_orange} },
    diffFile = { fg = ${text_blue} },
    diffLine = { fg = ${surface} },
    diffIndexLine = { fg = ${text_teal} },
    DiffAdd = { bg = ${surface_green} }, -- diff mode: Added line |diff.txt|
    DiffChange = { bg = ${surface_blue} }, -- diff mode: Changed line |diff.txt|
    DiffDelete = { bg = ${surface_red} }, -- diff mode: Deleted line |diff.txt|
    DiffText = { bg = ${surface_violet} }, -- diff mode: Changed text within a changed line |diff.txt|

    -- NeoVim
    healthError = { fg = ${text_error} },
    healthSuccess = { fg = ${text_ok} },
    healthWarning = { fg = ${text_warning} },

    -- rainbow
    rainbow1 = { fg = ${text_red} },
    rainbow2 = { fg = ${text_orange} },
    rainbow3 = { fg = ${text_yellow} },
    rainbow4 = { fg = ${text_green} },
    rainbow5 = { fg = ${text_sky} },
    rainbow6 = { fg = ${text_violet} },

    -- markdown
    markdownHeadingDelimiter = { fg = ${text_orange}, bold = true },
    markdownCode = { fg = ${text_rose} },
    markdownCodeBlock = { fg = ${text_rose} },
    markdownLinkText = { fg = ${text_link}, underline = true },
    markdownH1 = { link = 'rainbow1' },
    markdownH2 = { link = 'rainbow2' },
    markdownH3 = { link = 'rainbow3' },
    markdownH4 = { link = 'rainbow4' },
    markdownH5 = { link = 'rainbow5' },
    markdownH6 = { link = 'rainbow6' },

    -- }}}
    -- Diagnostics and LSP {{{

    LspReferenceText = { bg = ${surface_menu} }, -- used for highlighting "text" references
    LspReferenceRead = { bg = ${surface_menu} }, -- used for highlighting "read" references
    LspReferenceWrite = { bg = ${surface_menu} }, -- used for highlighting "write" references
    LspSignatureActiveParameter = { fg = ${text_indigo}, bold = true },
    LspCodeLens = { fg = ${text_variant_dimmer} }, -- virtual text of the codelens
    LspCodeLensSeparator = { link = 'LspCodeLens' }, -- virtual text of the codelens separators
    -- fg of `Comment` and bg of `CursorLine`.
    LspInlayHint = { fg = ${text_variant_dimmer}, bg = ${surface_cursorline} }, -- virtual text of the inlay hints
    LspInfoBorder = { link = 'FloatBorder' },

    DiagnosticOk = { fg = ${text_ok} },
    DiagnosticHint = { fg = ${text_hint} },
    DiagnosticInfo = { fg = ${text_info} },
    DiagnosticWarn = { fg = ${text_warning} },
    DiagnosticError = { fg = ${text_error} },
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
    DiagnosticUnderlineOk = { sp = ${text_ok}, undercurl = true }, -- Used to underline diagnostics
    DiagnosticUnderlineHint = { sp = ${text_hint}, undercurl = true },
    DiagnosticUnderlineInfo = { sp = ${text_info}, undercurl = true },
    DiagnosticUnderlineWarn = { sp = ${text_warning}, undercurl = true },
    DiagnosticUnderlineError = { sp = ${text_error}, undercurl = true },
    DiagnosticVirtualTextOk = { fg = ${on_surface_green}, bg = ${surface_green} }, -- Used as the mantle highlight group. Other Diagnostic highlights link to this by default
    DiagnosticVirtualTextHint = { fg = ${on_surface_violet}, bg = ${surface_violet} },
    DiagnosticVirtualTextInfo = { fg = ${on_surface_blue}, bg = ${surface_blue} },
    DiagnosticVirtualTextWarn = { fg = ${on_surface_amber}, bg = ${surface_amber} },
    DiagnosticVirtualTextError = { fg = ${on_surface_red}, bg = ${surface_red} },

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
    ['@variable'] = { fg = ${text} }, -- Any variable name that does not have another highlight.
    ['@variable.builtin'] = { fg = ${text_purple} }, -- Variable names that are defined by the languages, like this or self.
    ['@variable.parameter'] = { fg = ${text_red}, italic = true }, -- For parameters of a function.
    ['@variable.member'] = { fg = ${text_pink} }, -- For fields.

    ['@constant'] = { link = 'Constant' }, -- For constants
    ['@constant.builtin'] = { fg = ${text_orange} }, -- For constant that are built in the language: nil in Lua.
    ['@constant.macro'] = { link = 'Macro' }, -- For constants that are defined by macros: NULL in C.

    ['@module'] = { fg = ${text_amber}, italic = true }, -- For identifiers referring to modules and namespaces.
    ['@label'] = { link = 'Label' }, -- For labels: label: in C and :label: in Lua.

    -- Literals
    ['@string'] = { link = 'String' }, -- For strings.
    ['@string.documentation'] = { fg = ${text_teal} }, -- For strings documenting code (e.g. Python docstrings).
    ['@string.regexp'] = { fg = ${text_pink} }, -- For regexes.
    ['@string.escape'] = { fg = ${text_pink} }, -- For escape characters within a string.
    ['@string.special'] = { link = 'Special' }, -- other special strings (e.g. dates)
    ['@string.special.path'] = { link = 'Special' }, -- filenames
    ['@string.special.symbol'] = { fg = ${text_pink} }, -- symbols or atoms
    ['@string.special.url'] = { fg = ${text_link}, italic = true, underline = true }, -- urls, links and emails
    ['@punctuation.delimiter.regex'] = { link = '@string.regexp' },

    ['@character'] = { link = 'Character' }, -- character literals
    ['@character.special'] = { link = 'SpecialChar' }, -- special characters (e.g. wildcards)

    ['@boolean'] = { link = 'Boolean' }, -- For booleans.
    ['@number'] = { link = 'Number' }, -- For all numbers
    ['@number.float'] = { link = 'Float' }, -- For floats.

    -- Types
    ['@type'] = { link = 'Type' }, -- For types.
    ['@type.builtin'] = { fg = ${text_purple}, italic = true }, -- For builtin types.
    ['@type.definition'] = { link = 'Type' }, -- type definitions (e.g. `typedef` in C)

    ['@attribute'] = { link = 'Constant' }, -- attribute annotations (e.g. Python decorators)
    ['@property'] = { link = '@variable.member' }, -- For fields: same concept as @variable.member, one color for both so LSP "property" tokens (default-linked to @property) match treesitter's field captures. Overriden later for data languages and CSS.

    -- Functions
    ['@function'] = { link = 'Function' }, -- For function (calls and definitions).
    ['@function.builtin'] = { fg = ${text_orange} }, -- For builtin functions: table.insert in Lua.
    ['@function.call'] = { link = 'Function' }, -- function calls
    ['@function.macro'] = { link = 'Macro' }, -- For macro defined functions (calls and definitions): each macro_rules in Rust.

    ['@function.method'] = { link = 'Function' }, -- For method definitions.
    ['@function.method.call'] = { link = 'Function' }, -- For method calls.

    ['@constructor'] = { fg = ${text_amber} }, -- For constructor calls and definitions: = { } in Lua, and Java constructors.
    ['@operator'] = { link = 'Operator' }, -- For any operator: +, but also -> and * in C.

    -- Keywords
    ['@keyword'] = { link = 'Keyword' }, -- For keywords that don't fall in previous categories.
    ['@keyword.modifier'] = { link = 'Keyword' }, -- For keywords modifying other constructs (e.g. `const`, `static`, `public`)
    ['@keyword.type'] = { link = 'Keyword' }, -- For keywords describing composite types (e.g. `struct`, `enum`)
    ['@keyword.coroutine'] = { link = 'Keyword' }, -- For keywords related to coroutines (e.g. `go` in Go, `async/await` in Python)
    ['@keyword.function'] = { fg = ${text_indigo} }, -- For keywords used to define a function.
    ['@keyword.operator'] = { fg = ${text_indigo} }, -- For new keyword operator
    ['@keyword.import'] = { link = 'Include' }, -- For includes: #include in C, use or extern crate in Rust, or require in Lua.
    ['@keyword.repeat'] = { link = 'Repeat' }, -- For keywords related to loops.
    ['@keyword.return'] = { fg = ${text_indigo} },
    ['@keyword.debug'] = { link = 'Exception' }, -- For keywords related to debugging
    ['@keyword.exception'] = { link = 'Exception' }, -- For exception related keywords.

    ['@keyword.conditional'] = { link = 'Conditional' }, -- For keywords related to conditionnals.
    ['@keyword.conditional.ternary'] = { link = 'Operator' }, -- For ternary operators (e.g. `?` / `:`)

    ['@keyword.directive'] = { link = 'PreProc' }, -- various preprocessor directives & shebangs
    ['@keyword.directive.define'] = { link = 'Define' }, -- preprocessor definition directives
    ['@keyword.export'] = { fg = ${text_indigo} }, -- JS & derivative

    -- Punctuation
    ['@punctuation.delimiter'] = { link = 'Delimiter' }, -- For delimiters (e.g. `;` / `.` / `,`).
    ['@punctuation.bracket'] = { link = 'Punctuation' }, -- For brackets and parenthesis.
    ['@punctuation.special'] = { link = 'Special' }, -- For special punctuation that does not fall in the categories before (e.g. `{}` in string interpolation).

    -- Comment
    ['@comment'] = { link = 'Comment' },
    ['@comment.documentation'] = { link = 'Comment' }, -- For comments documenting code

    ['@comment.error'] = { fg = ${text_error}, bold = true },
    ['@comment.warning'] = { fg = ${text_warning}, bold = true },
    ['@comment.hint'] = { fg = ${text_hint}, bold = true },
    ['@comment.todo'] = { fg = ${text_info}, bold = true },
    ['@comment.note'] = { link = 'Title' },

    -- Markup
    ['@markup'] = { fg = ${text} }, -- For strings considerated text in a markup language.
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

    ['@markup.link'] = { fg = ${text_link}, underline = true }, -- text references, footnotes, citations, etc.
    ['@markup.link.label'] = { link = '@markup.link' }, -- link, reference descriptions
    ['@markup.link.url'] = { link = '@markup.link' }, -- urls, links and emails

    ['@markup.raw'] = { fg = ${text_green} }, -- used for inline code in markdown and for doc in python (""")

    ['@markup.list'] = { fg = ${text_teal} },
    ['@markup.list.checked'] = { fg = ${text_green} }, -- todo notes
    ['@markup.list.unchecked'] = { fg = ${text_dim} }, -- todo notes

    -- Diff
    ['@diff.plus'] = { link = 'diffAdded' }, -- added text (for diff files)
    ['@diff.minus'] = { link = 'diffRemoved' }, -- deleted text (for diff files)
    ['@diff.delta'] = { link = 'diffChanged' }, -- deleted text (for diff files)

    -- Tags
    ['@tag'] = { fg = ${text_blue} }, -- Tags like HTML tag names.
    ['@tag.builtin'] = { fg = ${text_blue} }, -- JSX tag names.
    ['@tag.attribute'] = { fg = ${text_amber}, italic = true }, -- XML/HTML attributes (foo in foo="bar").
    ['@tag.delimiter'] = { fg = ${text_teal} }, -- Tag delimiter like < > /

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

    ['@string.special.url.html'] = { fg = ${text_green} }, -- Links in href, src attributes.
    ['@markup.link.label.html'] = { fg = ${text} }, -- Text between <a></a> tags.
    ['@character.special.html'] = { fg = ${text_red} }, -- Symbols such as &nbsp;.

    -- CSS
    ['@property.css'] = { fg = ${text_blue} },
    ['@property.scss'] = { fg = ${text_blue} },
    ['@property.id.css'] = { fg = ${text_amber} },
    ['@property.class.css'] = { fg = ${text_amber} },
    ['@type.css'] = { fg = ${text_indigo} },
    ['@type.tag.css'] = { fg = ${text_blue} },
    ['@string.plain.css'] = { fg = ${text} },
    ['@keyword.directive.css'] = { link = 'Keyword' }, -- CSS at-rules: https://developer.mozilla.org/en-US/docs/Web/CSS/At-rule.

    -- Beancount
    ['@type.beancount'] = { link = 'Normal' }, -- Beancount's accounts.

    -- Lua
    ['@constructor.lua'] = { link = '@punctuation.bracket' }, -- For constructor calls and definitions: = { } in Lua.

    -- Python
    ['@constructor.python'] = { fg = ${text_sky} }, -- __init__(), __new__().

    -- C/CPP
    ['@keyword.import.c'] = { link = 'Include' },
    ['@keyword.import.cpp'] = { link = 'Include' },

    -- gitcommit
    ['@comment.warning.gitcommit'] = { fg = ${text_warning} },

    -- gitignore
    ['@string.special.path.gitignore'] = { fg = ${text} },

    -- }}}
    -- LSP semantic tokens {{{

    -- Semantic tokens paint OVER treesitter (priority 125 vs 100, see
    -- vim.hl.priorities), so any token type whose default link resolves to
    -- a different color than the treesitter capture on the same text makes
    -- the buffer shift colors when the server attaches. Every entry below
    -- either clears a token type that is coarser than treesitter's captures
    -- (an empty definition stops the dotted fallback and lets treesitter
    -- show through, see :h lsp-semantic-highlight), or pins it to the exact
    -- group treesitter uses for the same token. Core defaults already align
    -- the rest.

    -- One flat "keyword" bucket vs treesitter's @keyword.function/.return/
    -- .conditional/.import (indigo): without this, every keyword flattens
    -- to the plain Keyword style on attach (rust-analyzer, lua_ls, zls).
    ['@lsp.type.keyword'] = {},
    -- Whole-comment tokens would paint over @comment.todo/.error/.warning.
    ['@lsp.type.comment'] = {},
    -- Plain "variable" would flatten @variable.builtin (self, vim) and
    -- other granular captures back to the Normal fg.
    ['@lsp.type.variable'] = {},
    -- Defaults to @type.qualifier, which is undefined and falls back to
    -- @type (emerald); modifier keywords (const, static, pub) belong with
    -- Keyword, like treesitter's @keyword.modifier.
    ['@lsp.type.modifier'] = { link = 'Keyword' },

    -- Standard-library functions and methods (e.g. lua_ls on `print`,
    -- `table.insert`): same color treesitter gives builtins.
    ['@lsp.typemod.function.defaultLibrary'] = { link = '@function.builtin' },
    ['@lsp.typemod.method.defaultLibrary'] = { link = '@function.builtin' },

    -- Nix: nixd's token NAMES are arbitrary; it maps its own concepts onto
    -- the standard legend (nixd/lib/Controller/SemanticTokens.cpp):
    --   method    = attrset binding keys  -> @variable.member in treesitter
    --   type      = select attrpath (a.b) -> @variable.member in treesitter
    --   interface = variables from `with` -> plain @variable in treesitter
    --   macro     = true/false literals   -> @boolean in treesitter
    --   keyword   = builtins              -> covered by the global clear:
    --               treesitter already colors builtins (@function.builtin),
    --               import (@keyword.import), abort/throw (@keyword.exception).
    --   regexp    = null + lambda args + lambda formals: three concepts on
    --               one name; cleared, treesitter renders all three sites.
    ['@lsp.type.method.nix'] = { link = '@variable.member' },
    ['@lsp.type.type.nix'] = { link = '@variable.member' },
    ['@lsp.type.interface.nix'] = { link = '@variable' },
    ['@lsp.type.macro.nix'] = { link = '@boolean' },
    ['@lsp.type.regexp.nix'] = {},

    -- }}}
    -- }}}
    -- StatusLine {{{

    StatusLineFocusedPrimary = { fg = ${on_surface_statusline}, bold = true },
    StatusLineFocusedSecondary = { fg = ${on_surface_statusline_dimmer} },

    StatusLineUnfocusedPrimary = { fg = ${on_surface_statusline_dimmer}, bold = true },
    StatusLineUnfocusedSecondary = { fg = ${on_surface_statusline_dimmer} },

    -- }}}
    -- Cmp {{{

    CmpItemAbbr = { fg = ${text_dim} },
    CmpItemAbbrDeprecated = { fg = ${text_dim}, strikethrough = true },
    CmpItemKind = { fg = ${text_blue} },
    CmpItemMenu = { fg = ${text} },
    CmpItemAbbrMatch = { fg = ${text}, bold = true },
    CmpItemAbbrMatchFuzzy = { fg = ${text}, bold = true },

    -- kind support
    CmpItemKindSnippet = { fg = ${text_violet} },
    CmpItemKindKeyword = { fg = ${text_red} },
    CmpItemKindText = { fg = ${text_teal} },
    CmpItemKindMethod = { link = 'Function' },
    CmpItemKindConstructor = { link = 'Function' },
    CmpItemKindFunction = { link = 'Function' },
    CmpItemKindFolder = { link = 'Directory' },
    CmpItemKindModule = { fg = ${text_blue} },
    CmpItemKindConstant = { link = 'Constant' },
    CmpItemKindField = { fg = ${text_green} },
    CmpItemKindProperty = { fg = ${text_green} },
    CmpItemKindEnum = { fg = ${text_green} },
    CmpItemKindUnit = { fg = ${text_green} },
    CmpItemKindClass = { fg = ${text_amber} },
    CmpItemKindVariable = { fg = ${text_pink} },
    CmpItemKindFile = { fg = ${text_blue} },
    CmpItemKindInterface = { fg = ${text_amber} },
    CmpItemKindColor = { fg = ${text_red} },
    CmpItemKindReference = { fg = ${text_red} },
    CmpItemKindEnumMember = { fg = ${text_red} },
    CmpItemKindStruct = { fg = ${text_blue} },
    CmpItemKindValue = { fg = ${text_orange} },
    CmpItemKindEvent = { fg = ${text_blue} },
    CmpItemKindOperator = { fg = ${text_blue} },
    CmpItemKindTypeParameter = { fg = ${text_blue} },
    CmpItemKindCopilot = { fg = ${text_teal} },

    -- }}}
    -- Noice {{{

    NoiceCmdLine = { link = 'Normal' },
    NoiceCmdlinePopupBorder = { link = 'FloatBorder' },
    NoiceCmdLineIcon = { link = 'Normal' },
    NoiceCmdlineIconCmdline = { fg = ${text_emerald} },
    NoiceCmdlineIconLua = { fg = ${text_violet} },
    NoiceConfirmBorder = { fg = ${text_red} },

    -- }}}
    -- render markdown {{{

    RenderMarkdownH1 = { link = 'markdownH1' },
    RenderMarkdownH2 = { link = 'markdownH2' },
    RenderMarkdownH3 = { link = 'markdownH3' },
    RenderMarkdownH4 = { link = 'markdownH4' },
    RenderMarkdownH5 = { link = 'markdownH5' },
    RenderMarkdownH6 = { link = 'markdownH6' },
    RenderMarkdownCode = { bg = ${surface_dark} },
    RenderMarkdownCodeInline = { bg = ${surface_dark} },
    RenderMarkdownBullet = { fg = ${text_sky} },
    RenderMarkdownTableHead = { fg = ${text_blue} },
    RenderMarkdownTableRow = { fg = ${text_indigo} },
    RenderMarkdownSuccess = { fg = ${text_ok} },
    RenderMarkdownInfo = { fg = ${text_info} },
    RenderMarkdownHint = { fg = ${text_hint} },
    RenderMarkdownWarn = { fg = ${text_warning} },
    RenderMarkdownError = { fg = ${text_error} },

    -- }}}
    -- Snacks {{{

    SnacksNormal = { link = 'Normal' },
    SnacksWinBar = { link = 'Title' },
    SnacksBackdrop = { link = 'FloatShadow' },
    SnacksNormalNC = { link = 'NormalFloat' },
    SnacksWinBarNC = { link = 'SnacksWinBar' },

    SnacksNotifierInfo = { link = 'DiagnosticInfo' },
    SnacksNotifierIconInfo = { link = 'DiagnosticInfo' },
    SnacksNotifierTitleInfo = { fg = ${text_info}, italic = true },
    SnacksNotifierBorderInfo = { link = 'DiagnosticInfo' },
    SnacksNotifierFooterInfo = { link = 'DiagnosticInfo' },
    SnacksNotifierWarn = { link = 'DiagnosticWarn' },
    SnacksNotifierIconWarn = { link = 'DiagnosticWarn' },
    SnacksNotifierTitleWarn = { fg = ${text_warning}, italic = true },
    SnacksNotifierBorderWarn = { link = 'DiagnosticWarn' },
    SnacksNotifierFooterWarn = { link = 'DiagnosticWarn' },
    SnacksNotifierDebug = { link = 'DiagnosticHint' },
    SnacksNotifierIconDebug = { link = 'DiagnosticHint' },
    SnacksNotifierTitleDebug = { fg = ${text_hint}, italic = true },
    SnacksNotifierBorderDebug = { link = 'DiagnosticHint' },
    SnacksNotifierFooterDebug = { link = 'DiagnosticHint' },
    SnacksNotifierError = { link = 'DiagnosticError' },
    SnacksNotifierIconError = { link = 'DiagnosticError' },
    SnacksNotifierTitleError = { fg = ${text_error}, italic = true },
    SnacksNotifierBorderError = { link = 'DiagnosticError' },
    SnacksNotifierFooterError = { link = 'DiagnosticError' },
    SnacksNotifierTrace = { fg = ${text_fuchsia} },
    SnacksNotifierIconTrace = { fg = ${text_fuchsia} },
    SnacksNotifierTitleTrace = { fg = ${text_fuchsia}, italic = true },
    SnacksNotifierBorderTrace = { fg = ${text_fuchsia} },
    SnacksNotifierFooterTrace = { fg = ${text_fuchsia} },

    SnacksDashboardNormal = { link = 'Normal' },
    SnacksDashboardDesc = { fg = ${text_blue} },
    SnacksDashboardFile = { fg = ${text_indigo} },
    SnacksDashboardDir = { link = 'NonText' },
    SnacksDashboardFooter = { fg = ${text_amber}, italic = true },
    SnacksDashboardHeader = { fg = ${text_blue} },
    SnacksDashboardIcon = { fg = ${text_pink}, bold = true },
    SnacksDashboardKey = { fg = ${text_orange} },
    SnacksDashboardTerminal = { link = 'SnacksDashboardNormal' },
    SnacksDashboardSpecial = { link = 'Special' },
    SnacksDashboardTitle = { link = 'Title' },

    SnacksIndent = { fg = ${surface} },
    SnacksIndentScope = { fg = ${text} },

    SnacksPickerSelected = { fg = ${text_pink}, bg = ${surface}, bold = true },
    SnacksPickerMatch = { fg = ${text_blue} },

    SnacksPicker = { link = 'NormalFloat' },
    SnacksPickerBorder = { link = 'FloatBorder' },
    SnacksPickerDir = { link = 'SnacksPickerDimmed' },
    SnacksPickerDimmed = { fg = ${text_dimmer} },
    SnacksPickerInputBorder = { link = 'SnacksPickerBorder' },
    SnacksPickerInput = { link = 'NormalFloat' },
    SnacksPickerPrompt = { fg = ${text_pink} },
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
    CompileModeCommandOutput = { fg = ${text_blue} },
    CompileModeOutputFile = { link = 'Normal' },
    CompileModeCheckResult = { bold = true },
    CompileModeCheckTarget = { link = 'Normal' },
    CompileModeDirectoryMessage = { link = 'Normal' },
    CompileModeErrorLocus = { link = 'Normal' },

    -- }}}
  }
''
