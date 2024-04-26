local wezterm = require 'wezterm'

-- Load the builtin Catppuccin colorscheme.
local catppuccin_mocha = wezterm.color.get_builtin_schemes()['Catppuccin Mocha']
catppuccin_mocha.tab_bar.background = catppuccin_mocha.ansi[8]

-- Periodically update the status bar.
wezterm.on('update-status',
  ---@diagnostic disable-next-line: unused-local
  function(window, pane)
    local date = wezterm.strftime '%Y-%m-%d %H:%M';

    window:set_left_status(wezterm.format {
      { Background = { Color = catppuccin_mocha.ansi[8] } },
      { Foreground = { Color = catppuccin_mocha.background } },
      { Text = '  ' },
      { Attribute = { Intensity = 'Bold' } },
      { Text = date },
      { Attribute = { Intensity = 'Normal' } },
      { Text = '  ' },
    });

    window:set_right_status(wezterm.format {
      { Background = { Color = catppuccin_mocha.ansi[8] } },
      { Foreground = { Color = catppuccin_mocha.background } },
      { Text = '  ' },
    });
  end
)

wezterm.on(
  'format-tab-title',
  ---@diagnostic disable-next-line: unused-local
  function(tab, tabs, panes, config, hover, max_width)
    return {
      { Foreground = { Color = catppuccin_mocha.ansi[8] } },
      { Background = { Color = 'none' } },
      { Text = wezterm.nerdfonts.ple_upper_left_triangle },
      { Background = { Color = 'none' } },
      { Foreground = { Color = tab.is_active and catppuccin_mocha.ansi[2] or catppuccin_mocha.brights[8] } },
      { Attribute = { Intensity = tab.is_active and 'Bold' or 'Normal' } },
      { Text = string.format(' %d ', tab.tab_index) },
      { Foreground = { Color = catppuccin_mocha.ansi[8] } },
      { Background = { Color = 'none' } },
      { Text = wezterm.nerdfonts.ple_lower_right_triangle },
    }
  end
)

-- Create config object.
local config = wezterm.config_builder()

config.color_schemes = { ['Catppuccin Mocha Custom'] = catppuccin_mocha }
config.color_scheme = 'Catppuccin Mocha Custom'
config.font = wezterm.font_with_fallback {
  'Iosevka Term Curly',
  'Symbols Nerd Font',
  'Material Design Icons Desktop',
  'Motomachi',
}
-- Font size 14 for the best rendering.  Might be on the smaller side at some DPI/screen resolutions.
config.font_size = 14
config.bold_brightens_ansi_colors = false
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_padding = { top = 48, left = 0, right = 0, bottom = 0 }
config.hyperlink_rules = {
  { regex = '\\b\\w+://(?:[\\w.-]+)\\.[a-z]{2,15}\\S*\\b', format = '$0' },
  { regex = '\\b\\w+://(?:[\\w.-]+)\\S*\\b',               format = '$0' },
  { regex = '\\bfile://\\S*\\b',                           format = '$0' },
  { regex = '\\bb/(\\d+)\\b',                              format = 'https://b.corp.google.com/issues/$1' },
  { regex = '\\bcl/(\\d+)\\b',                             format = 'https://critique.corp.google.com/issues/$1' },
}

return config
