-- Helpers {{{

---@param groups {[string]: table}
local function generate_colorscheme(groups)
  if type(groups) ~= 'table' then
    error('generate_colorscheme: invalid parameter: expected a table, got ' .. type(groups))
  end

  for group, setting in pairs(groups) do
    vim.api.nvim_set_hl(0, group, setting)
  end
end

-- }}}
-- Palette {{{

local P = {
  ['amber-100'] = 0xFEF3C6,
  ['amber-200'] = 0xFEE685,
  ['amber-300'] = 0xFFD230,
  ['amber-400'] = 0xFFB900,
  ['amber-50'] = 0xFFFBEB,
  ['amber-500'] = 0xFE9A00,
  ['amber-600'] = 0xE17100,
  ['amber-700'] = 0xBB4D00,
  ['amber-800'] = 0x973C00,
  ['amber-900'] = 0x7B3306,
  ['amber-950'] = 0x461901,
  ['blue-100'] = 0xDBEAFE,
  ['blue-200'] = 0xBEDBFF,
  ['blue-300'] = 0x8EC5FF,
  ['blue-400'] = 0x51A2FF,
  ['blue-50'] = 0xEFF6FF,
  ['blue-500'] = 0x2B7FFF,
  ['blue-600'] = 0x155DFC,
  ['blue-700'] = 0x1447E6,
  ['blue-800'] = 0x193CB8,
  ['blue-900'] = 0x1C398E,
  ['blue-950'] = 0x162456,
  ['cyan-100'] = 0xCEFAFE,
  ['cyan-200'] = 0xA2F4FD,
  ['cyan-300'] = 0x53EAFD,
  ['cyan-400'] = 0x00D3F2,
  ['cyan-50'] = 0xECFEFF,
  ['cyan-500'] = 0x00B8DB,
  ['cyan-600'] = 0x0092B8,
  ['cyan-700'] = 0x007595,
  ['cyan-800'] = 0x005F78,
  ['cyan-900'] = 0x104E64,
  ['cyan-950'] = 0x053345,
  ['emerald-100'] = 0xD0FAE5,
  ['emerald-200'] = 0xA4F4CF,
  ['emerald-300'] = 0x5EE9B5,
  ['emerald-400'] = 0x00D492,
  ['emerald-50'] = 0xECFDF5,
  ['emerald-500'] = 0x00BC7D,
  ['emerald-600'] = 0x009966,
  ['emerald-700'] = 0x007A55,
  ['emerald-800'] = 0x006045,
  ['emerald-900'] = 0x004F3B,
  ['emerald-950'] = 0x002C22,
  ['fuchsia-100'] = 0xFAE8FF,
  ['fuchsia-200'] = 0xF6CFFF,
  ['fuchsia-300'] = 0xF4A8FF,
  ['fuchsia-400'] = 0xED6AFF,
  ['fuchsia-50'] = 0xFDF4FF,
  ['fuchsia-500'] = 0xE12AFB,
  ['fuchsia-600'] = 0xC800DE,
  ['fuchsia-700'] = 0xA800B7,
  ['fuchsia-800'] = 0x8A0194,
  ['fuchsia-900'] = 0x721378,
  ['fuchsia-950'] = 0x4B004F,
  ['gray-100'] = 0xF3F4F6,
  ['gray-200'] = 0xE5E7EB,
  ['gray-300'] = 0xD1D5DC,
  ['gray-400'] = 0x99A1AF,
  ['gray-50'] = 0xF9FAFB,
  ['gray-500'] = 0x6A7282,
  ['gray-600'] = 0x4A5565,
  ['gray-700'] = 0x364153,
  ['gray-800'] = 0x1E2939,
  ['gray-900'] = 0x101828,
  ['gray-950'] = 0x030712,
  ['green-100'] = 0xDCFCE7,
  ['green-200'] = 0xB9F8CF,
  ['green-300'] = 0x7BF1A8,
  ['green-400'] = 0x05DF72,
  ['green-50'] = 0xF0FDF4,
  ['green-500'] = 0x00C950,
  ['green-600'] = 0x00A63E,
  ['green-700'] = 0x008236,
  ['green-800'] = 0x016630,
  ['green-900'] = 0x0D542B,
  ['green-950'] = 0x032E15,
  ['indigo-100'] = 0xE0E7FF,
  ['indigo-200'] = 0xC6D2FF,
  ['indigo-300'] = 0xA3B3FF,
  ['indigo-400'] = 0x7C86FF,
  ['indigo-50'] = 0xEEF2FF,
  ['indigo-500'] = 0x615FFF,
  ['indigo-600'] = 0x4F39F6,
  ['indigo-700'] = 0x432DD7,
  ['indigo-800'] = 0x372AAC,
  ['indigo-900'] = 0x312C85,
  ['indigo-950'] = 0x1E1A4D,
  ['lime-100'] = 0xECFCCA,
  ['lime-200'] = 0xD8F999,
  ['lime-300'] = 0xBBF451,
  ['lime-400'] = 0x9AE600,
  ['lime-50'] = 0xF7FEE7,
  ['lime-500'] = 0x7CCF00,
  ['lime-600'] = 0x5EA500,
  ['lime-700'] = 0x497D00,
  ['lime-800'] = 0x3C6300,
  ['lime-900'] = 0x35530E,
  ['lime-950'] = 0x192E03,
  ['mauve-100'] = 0xF3F1F3,
  ['mauve-200'] = 0xE7E4E7,
  ['mauve-300'] = 0xD7D0D7,
  ['mauve-400'] = 0xA89EA9,
  ['mauve-50'] = 0xFAFAFA,
  ['mauve-500'] = 0x79697B,
  ['mauve-600'] = 0x594C5B,
  ['mauve-700'] = 0x463947,
  ['mauve-800'] = 0x2A212C,
  ['mauve-900'] = 0x1D161E,
  ['mauve-950'] = 0x070B0A,
  ['mist-100'] = 0xF1F3F3,
  ['mist-200'] = 0xE3E7E8,
  ['mist-300'] = 0xD0D6D8,
  ['mist-400'] = 0x9CA8AB,
  ['mist-50'] = 0xF9FBFB,
  ['mist-500'] = 0x67787C,
  ['mist-600'] = 0x4B585B,
  ['mist-700'] = 0x3A4542,
  ['mist-800'] = 0x22292B,
  ['mist-900'] = 0x161B1D,
  ['mist-950'] = 0x090B0C,
  ['neutral-100'] = 0xF5F5F5,
  ['neutral-200'] = 0xE5E5E5,
  ['neutral-300'] = 0xD4D4D4,
  ['neutral-400'] = 0xA1A1A1,
  ['neutral-50'] = 0xFAFAFA,
  ['neutral-500'] = 0x737373,
  ['neutral-600'] = 0x525252,
  ['neutral-700'] = 0x404040,
  ['neutral-800'] = 0x262626,
  ['neutral-900'] = 0x171717,
  ['neutral-950'] = 0x0A0A0A,
  ['olive-100'] = 0xF4F4F0,
  ['olive-200'] = 0xE8E8E3,
  ['olive-300'] = 0xD8D8D0,
  ['olive-400'] = 0xABAB9C,
  ['olive-50'] = 0xFBFBF9,
  ['olive-500'] = 0x7C7C67,
  ['olive-600'] = 0x5B5B4B,
  ['olive-700'] = 0x474739,
  ['olive-800'] = 0x2B2B22,
  ['olive-900'] = 0x1D1D16,
  ['olive-950'] = 0x0C0C09,
  ['orange-100'] = 0xFFEDD4,
  ['orange-200'] = 0xFFD6A7,
  ['orange-300'] = 0xFFB86A,
  ['orange-400'] = 0xFF8904,
  ['orange-50'] = 0xFFF7ED,
  ['orange-500'] = 0xFF6900,
  ['orange-600'] = 0xF54900,
  ['orange-700'] = 0xCA3500,
  ['orange-800'] = 0x9F2D00,
  ['orange-900'] = 0x7E2A0C,
  ['orange-950'] = 0x441306,
  ['pink-100'] = 0xFCE7F3,
  ['pink-200'] = 0xFCCEE8,
  ['pink-300'] = 0xFDA5D5,
  ['pink-400'] = 0xFB64B6,
  ['pink-50'] = 0xFDF2F8,
  ['pink-500'] = 0xF6339A,
  ['pink-600'] = 0xE60076,
  ['pink-700'] = 0xC6005C,
  ['pink-800'] = 0xA3004C,
  ['pink-900'] = 0x861043,
  ['pink-950'] = 0x510424,
  ['purple-100'] = 0xF3E8FF,
  ['purple-200'] = 0xE9D4FF,
  ['purple-300'] = 0xDAB2FF,
  ['purple-400'] = 0xC27AFF,
  ['purple-50'] = 0xFAF5FF,
  ['purple-500'] = 0xAD46FF,
  ['purple-600'] = 0x9810FA,
  ['purple-700'] = 0x8200DB,
  ['purple-800'] = 0x6E11B0,
  ['purple-900'] = 0x59168B,
  ['purple-950'] = 0x3C0366,
  ['red-100'] = 0xFFE2E2,
  ['red-200'] = 0xFFC9C9,
  ['red-300'] = 0xFFA2A2,
  ['red-400'] = 0xFF6467,
  ['red-50'] = 0xFEF2F2,
  ['red-500'] = 0xFB2C36,
  ['red-600'] = 0xE7000B,
  ['red-700'] = 0xC10007,
  ['red-800'] = 0x9F0712,
  ['red-900'] = 0x82181A,
  ['red-950'] = 0x460809,
  ['rose-100'] = 0xFFE4E6,
  ['rose-200'] = 0xFFCCD3,
  ['rose-300'] = 0xFFA1AD,
  ['rose-400'] = 0xFF637E,
  ['rose-50'] = 0xFFF1F2,
  ['rose-500'] = 0xFF2056,
  ['rose-600'] = 0xEC003F,
  ['rose-700'] = 0xC70036,
  ['rose-800'] = 0xA50036,
  ['rose-900'] = 0x8B0836,
  ['rose-950'] = 0x4D0218,
  ['sky-100'] = 0xDFF2FE,
  ['sky-200'] = 0xB8E6FE,
  ['sky-300'] = 0x74D4FF,
  ['sky-400'] = 0x00BCFF,
  ['sky-50'] = 0xF0F9FF,
  ['sky-500'] = 0x00A6F4,
  ['sky-600'] = 0x0084D1,
  ['sky-700'] = 0x0069A8,
  ['sky-800'] = 0x00598A,
  ['sky-900'] = 0x024A70,
  ['sky-950'] = 0x052F4A,
  ['slate-100'] = 0xF1F5F9,
  ['slate-200'] = 0xE2E8F0,
  ['slate-300'] = 0xCAD5E2,
  ['slate-400'] = 0x90A1B9,
  ['slate-50'] = 0xF8FAFC,
  ['slate-500'] = 0x62748E,
  ['slate-600'] = 0x45556C,
  ['slate-700'] = 0x314158,
  ['slate-800'] = 0x1D293D,
  ['slate-900'] = 0x0F172B,
  ['slate-950'] = 0x020618,
  ['stone-100'] = 0xF5F5F4,
  ['stone-200'] = 0xE7E5E4,
  ['stone-300'] = 0xD6D3D1,
  ['stone-400'] = 0xA6A09B,
  ['stone-50'] = 0xFAFAF9,
  ['stone-500'] = 0x79716B,
  ['stone-600'] = 0x57534D,
  ['stone-700'] = 0x44403B,
  ['stone-800'] = 0x292524,
  ['stone-900'] = 0x1C1917,
  ['stone-950'] = 0x0C0A09,
  ['taupe-100'] = 0xF3F1F1,
  ['taupe-200'] = 0xE8E4E3,
  ['taupe-300'] = 0xD8D2D0,
  ['taupe-400'] = 0xABA09C,
  ['taupe-50'] = 0xFBFAF9,
  ['taupe-500'] = 0x7C6D67,
  ['taupe-600'] = 0x5B4F4B,
  ['taupe-700'] = 0x473C39,
  ['taupe-800'] = 0x2B2422,
  ['taupe-900'] = 0x1D1816,
  ['taupe-950'] = 0x0C0A09,
  ['teal-100'] = 0xCBFBF1,
  ['teal-200'] = 0x96F7E4,
  ['teal-300'] = 0x46ECD5,
  ['teal-400'] = 0x00D5BE,
  ['teal-50'] = 0xF0FDFA,
  ['teal-500'] = 0x00BBA7,
  ['teal-600'] = 0x009689,
  ['teal-700'] = 0x00786F,
  ['teal-800'] = 0x005F5A,
  ['teal-900'] = 0x0B4F4A,
  ['teal-950'] = 0x022F2E,
  ['violet-100'] = 0xEDE9FE,
  ['violet-200'] = 0xDDD6FF,
  ['violet-300'] = 0xC4B4FF,
  ['violet-400'] = 0xA684FF,
  ['violet-50'] = 0xF5F3FF,
  ['violet-500'] = 0x8E51FF,
  ['violet-600'] = 0x7F22FE,
  ['violet-700'] = 0x7008E7,
  ['violet-800'] = 0x5D0EC0,
  ['violet-900'] = 0x4D179A,
  ['violet-950'] = 0x2F0D68,
  ['yellow-100'] = 0xFEF9C2,
  ['yellow-200'] = 0xFFF085,
  ['yellow-300'] = 0xFFDF20,
  ['yellow-400'] = 0xFDC700,
  ['yellow-50'] = 0xFEFCE8,
  ['yellow-500'] = 0xF0B100,
  ['yellow-600'] = 0xD08700,
  ['yellow-700'] = 0xA65F00,
  ['yellow-800'] = 0x894B00,
  ['yellow-900'] = 0x733E0A,
  ['yellow-950'] = 0x432004,
  ['zinc-100'] = 0xF4F4F5,
  ['zinc-200'] = 0xE4E4E7,
  ['zinc-300'] = 0xD4D4D8,
  ['zinc-400'] = 0x9F9FA9,
  ['zinc-50'] = 0xFAFAFA,
  ['zinc-500'] = 0x71717B,
  ['zinc-600'] = 0x52525C,
  ['zinc-700'] = 0x3F3F46,
  ['zinc-800'] = 0x27272A,
  ['zinc-900'] = 0x18181B,
  ['zinc-950'] = 0x09090B,
}

-- }}}
-- Theme {{{

T = {
  text = P['zinc-300'],
  text_dim = P['zinc-400'],
  text_dimmer = P['zinc-500'],
  text_dimmest = P['zinc-600'],
  text_conceal = P['zinc-700'],

  text_variant = P['slate-300'],
  text_variant_dim = P['slate-400'],
  text_variant_dimmer = P['slate-500'],
  text_variant_dimmest = P['slate-600'],
  text_variant_conceal = P['slate-700'],

  text_red = P['red-300'],
  text_orange = P['orange-300'],
  text_amber = P['amber-400'],
  text_yellow = P['yellow-400'],
  text_lime = P['lime-400'],
  text_green = P['green-300'],
  text_emerald = P['emerald-300'],
  text_teal = P['teal-300'],
  text_cyan = P['cyan-300'],
  text_sky = P['sky-300'],
  text_blue = P['blue-300'],
  text_indigo = P['indigo-300'],
  text_violet = P['violet-300'],
  text_purple = P['purple-300'],
  text_fuchsia = P['fuchsia-300'],
  text_pink = P['pink-300'],
  text_rose = P['rose-300'],

  text_title = P['zinc-100'],
  text_link = P['blue-300'],
  text_function = P['blue-300'],
  text_comment = P['slate-500'],

  text_ok = P['green-300'],
  text_error = P['red-300'],
  text_warning = P['amber-400'],
  text_info = P['blue-300'],
  text_hint = P['indigo-300'],

  text_lineno = P['zinc-700'],
  text_lineno_cursor = P['zinc-400'],

  borders = P['zinc-600'],

  surface_dark = P['zinc-950'],
  surface = P['zinc-900'],
  surface_cursorline = P['zinc-800'],
  surface_menu = P['zinc-950'],
  surface_menu_cursorline = P['zinc-800'],

  surface_scrollbar = 0x121212,
  surface_scrollbar_thumb = P['zinc-800'],

  surface_cursor = P['orange-400'],
  on_surface_cursor = P['zinc-900'],

  surface_visual = P['blue-800'],
  on_surface_visual = P['blue-50'],

  surface_statusline = P['zinc-800'],
  surface_statusline_dim = P['zinc-700'],
  surface_statusline_dimmer = P['zinc-600'],
  on_surface_statusline = P['zinc-300'],
  on_surface_statusline_dim = P['zinc-400'],
  on_surface_statusline_dimmer = P['zinc-500'],
  on_surface_statusline_dimmest = P['zinc-600'],

  -- Same as `surface_amber`/`on_surface_amber`
  surface_search = 0x343121, -- surface + amber-300/15
  on_surface_search = P['amber-200'],

  surface_red = 0x352932, -- surface + red-300/15
  on_surface_red = P['red-200'],

  surface_green = 0x203533, -- surface + green-300/15
  on_surface_green = P['green-200'],

  surface_amber = 0x343121, -- surface + amber-300/15
  on_surface_amber = P['amber-200'],

  surface_blue = 0x232F41, -- surface + blue-300/15
  on_surface_blue = P['blue-200'],

  surface_violet = 0x2B2C41, -- surface + violet-300/15
  on_surface_violet = P['violet-200'],

  NONE = 'NONE',
  UNUSED = 0xFF00FF,
}

-- }}}
-- Terminal groups {{{

vim.g.terminal_color_0 = T.surface
vim.g.terminal_color_8 = T.text_dimmer

vim.g.terminal_color_1 = T.text_red
vim.g.terminal_color_9 = P['red-200']

vim.g.terminal_color_2 = T.text_green
vim.g.terminal_color_10 = P['green-200']

vim.g.terminal_color_3 = T.text_amber
vim.g.terminal_color_11 = P['amber-300']

vim.g.terminal_color_4 = T.text_blue
vim.g.terminal_color_12 = P['blue-200']

vim.g.terminal_color_5 = T.text_fuchsia
vim.g.terminal_color_13 = P['fuchsia-200']

vim.g.terminal_color_6 = T.text_cyan
vim.g.terminal_color_14 = P['cyan-200']

vim.g.terminal_color_7 = T.text
vim.g.terminal_color_15 = P['zinc-100']

--- }}}

generate_colorscheme {

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
  FloatBorder = { fg = T.borders, bg = T.NONE },
  FloatTitle = { link = 'Title' }, -- Title of floating windows
  FloatShadow = { fg = T.NONE },
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
  Number = { fg = T.text_red }, --   a number constant: 234, 0xff
  Float = { link = 'Number' }, -- a floating point constant: 2.3e10
  Boolean = { fg = T.text_cyan }, -- a boolean constant: TRUE, false
  Identifier = { fg = T.text }, -- (preferred) any variable name
  Function = { fg = T.text_function }, -- function name (also: methods for classes)
  Statement = { fg = T.text, bold = true }, -- (preferred) any statement
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

  StorageClass = { fg = T.text_amber }, -- static, register, volatile, etc.
  Structure = { fg = T.text_amber }, --  struct, union, enum, etc.
  Special = { fg = T.text_pink }, -- (preferred) any special symbol
  Type = { fg = T.text_amber }, -- (preferred) int, long, char, etc.
  Typedef = { link = 'Type' }, --  A typedef
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
  ['@variable.parameter'] = { fg = T.text_red, italic = true }, -- For parameters of a function.
  ['@variable.member'] = { fg = T.text_pink }, -- For fields.

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
  ['@property'] = { fg = T.text_function }, -- For fields, like accessing `bar` property on `foo.bar`. Overriden later for data languages and CSS.

  -- Functions
  ['@function'] = { link = 'Function' }, -- For function (calls and definitions).
  ['@function.builtin'] = { fg = T.text_orange }, -- For builtin functions: table.insert in Lua.
  ['@function.call'] = { link = 'Function' }, -- function calls
  ['@function.macro'] = { link = 'Macro' }, -- For macro defined functions (calls and definitions): each macro_rules in Rust.

  ['@function.method'] = { link = 'Function' }, -- For method definitions.
  ['@function.method.call'] = { link = 'Function' }, -- For method calls.

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
  -- LSP semantic tokens {{{

  -- Lua
  ['@lsp.mod.defaultLibrary.lua'] = { link = '@function.builtin.lua' },
  ['@lsp.typemod.function.defaultLibrary.lua'] = { link = '@function.builtin.lua' },

  -- }}}
  -- }}}
  -- StatusLine {{{

  StatusLineFocusedPrimary = { fg = T.on_surface_statusline, bold = true },
  StatusLineFocusedSecondary = { fg = T.on_surface_statusline_dim },

  StatusLineUnfocusedPrimary = { fg = T.on_surface_statusline_dim, bold = true },
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
