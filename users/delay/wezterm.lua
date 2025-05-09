local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font.
local function create_font_config(font_opts)
	local recursiveMono = {
		family = "Recursive Mono Casual Static",
		-- https://www.recursive.design/assets/arrowtype-recursive-sansmono-specimen-230407.pdf
		-- See also https://github.com/fish-shell/fish-shell/issues/10830 for why
		-- some ligatures do not work in Fish. (tl;dr: the individual characters are
		-- highlighted with different colors.)
		harfbuzz_features = {
			"calt",
			"clig",
			"dlig",
			"liga",
			-- "ss01", -- Single-story 'a'
			-- "ss02", -- Single-story 'g'
			"ss03", -- Simplified 'f'
			"ss04", -- Simplified 'i'
			"ss05", -- Simplified 'l'
			"ss06", -- Simplified 'r'
			-- "ss07", -- Simplified italic diagonals
			-- "ss08", -- Simplified 'L' & 'Z'
			-- "ss09", -- Simplified '6' & '9'
			"ss10", -- Dotted '0'
			-- "ss11", -- Simplified '1'
			"ss12", -- Simplified '@'
		},
	}

	for k, v in pairs(font_opts or {}) do
		recursiveMono[k] = v
	end

	return wezterm.font_with_fallback({
		recursiveMono,
		"Noto Sans Mono CJK JP",
	})
end

config.font = create_font_config()
config.font_size = 16.0

-- Theme: Catppuccin Obsidian.
local catppuccinObsidian = wezterm.get_builtin_color_schemes()["Catppuccin Mocha"]
catppuccinObsidian.background = "#11181c"
catppuccinObsidian.foreground = "#e1e8f4"
catppuccinObsidian.selection_bg = "#303747"
catppuccinObsidian.selection_fg = "#e1e8f4"
catppuccinObsidian.cursor_bg = "#fec49a"
catppuccinObsidian.ansi = {
	"#bac2de",
	"#fe9aa4",
	"#addba9",
	"#f3dfb4",
	"#95b7ef",
	"#b4befe",
	"#92d8d2",
	"#e1e8f4",
}
catppuccinObsidian.brights = {
	"#7a8390",
	"#fe818d",
	"#8ed29c",
	"#f1b48e",
	"#89b5fa",
	"#d0aff8",
	"#71d1c7",
	"#90a4bb",
}
config.color_schemes = {
	["Catppuccin Obsidian"] = catppuccinObsidian,
}
config.color_scheme = "Catppuccin Obsidian"
config.bold_brightens_ansi_colors = false

-- UI.
config.cursor_thickness = "1pt"
config.enable_tab_bar = false
config.enable_scroll_bar = false
config.window_padding = {
	left = "4pt",
	right = "4pt",
	top = "4pt",
	bottom = "4pt",
}

return config
