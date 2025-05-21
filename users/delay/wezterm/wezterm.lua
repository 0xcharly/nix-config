local wezterm = require("wezterm")
local config = wezterm.config_builder()

local is_darwin = function()
	return wezterm.target_triple:find("darwin") ~= nil
end

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
if is_darwin() then
	config.font_size = 14.0
else
	config.font_size = 10.0
end

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
catppuccinObsidian.tab_bar = {
	background = "#11181c",
	new_tab = {
		bg_color = "#11181c",
		fg_color = "#7a8490",
	},
}
config.color_schemes = {
	["Catppuccin Obsidian"] = catppuccinObsidian,
}
config.color_scheme = "Catppuccin Obsidian"
config.bold_brightens_ansi_colors = false

-- Keybindings.
config.leader = { key = "w", mods = "ALT", timeout_milliseconds = 1000 }

config.keys = {
	{ key = "f", mods = "LEADER", action = wezterm.action_callback(require("sessionizer").select) },
	{ key = "d", mods = "LEADER", action = wezterm.action.DetachDomain("CurrentPaneDomain") },
	{ key = '"', mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "%", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
	{ key = "[", mods = "LEADER", action = wezterm.action.ActivateCopyMode },
	{ key = "]", mods = "LEADER", action = wezterm.action.PasteFrom("PrimarySelection") },

	-- Disable default keybindings.
	{ key = "Enter", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },
}

-- UI.
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
	left = "4pt",
	right = "4pt",
	top = "4pt",
	bottom = "4pt",
}

if is_darwin() then
	config.window_decorations = "RESIZE"
end

wezterm.on(
	"format-tab-title",
	---@diagnostic disable-next-line: unused-local
	function(tab, _tabs, _panes, _config, _hover, _max_width)
		local title = tab.tab_index
		if tab.is_active then
			return {
				{ Background = { Color = "#203147" } },
				{ Foreground = { Color = "#9fcdfe" } },
				{ Text = " " .. title .. " " },
			}
		end
		return {
			{ Background = { Color = "#11181c" } },
			{ Foreground = { Color = "#7a8490" } },
			{ Text = " " .. title .. " " },
		}
	end
)
---@diagnostic disable-next-line: unused-local
wezterm.on("update-right-status", function(window, _pane)
	window:set_right_status(window:active_workspace())
end)

return config
