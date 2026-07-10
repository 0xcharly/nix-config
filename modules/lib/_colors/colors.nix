# Palette inspired by https://github.com/catppuccin/catppuccin
# MIT License: Copyright (c) 2021 Catppuccin
{
  tailwind,
  blends,
  others,
}:
rec {
  text = tailwind.zinc-300;
  text_dim = tailwind.zinc-400;
  text_dimmer = tailwind.zinc-500;
  text_dimmest = tailwind.zinc-600;
  text_conceal = tailwind.zinc-700;

  text_variant = tailwind.slate-300;
  text_variant_dim = tailwind.slate-400;
  text_variant_dimmer = tailwind.slate-500;
  text_variant_dimmest = tailwind.slate-600;
  text_variant_conceal = tailwind.slate-700;

  text_red = tailwind.red-300;
  text_orange = tailwind.orange-300;
  text_amber = tailwind.amber-200;
  text_yellow = tailwind.yellow-200;
  text_lime = tailwind.lime-400;
  text_green = tailwind.green-300;
  text_emerald = tailwind.emerald-300;
  text_teal = tailwind.teal-300;
  text_cyan = tailwind.cyan-300;
  text_sky = tailwind.sky-300;
  text_blue = tailwind.blue-300;
  text_indigo = tailwind.indigo-300;
  text_violet = tailwind.violet-300;
  text_purple = tailwind.purple-300;
  text_fuchsia = tailwind.fuchsia-300;
  text_pink = tailwind.pink-300;
  text_rose = tailwind.rose-300;

  text_title = tailwind.zinc-100;
  text_link = text_blue;
  text_function = text_blue;
  text_comment = text_variant_dimmer;

  text_ok = text_green;
  text_error = text_red;
  text_warning = text_amber;
  text_info = text_blue;
  text_hint = text_indigo;

  text_lineno = tailwind.zinc-700;
  text_lineno_cursor = tailwind.zinc-400;

  accent = tailwind.orange-300;
  accent_dark = tailwind.orange-400;
  accent_darker = tailwind.orange-500;
  accent_darkest = tailwind.orange-600;
  accent_surface = surface_amber;

  accent_secondary = tailwind.blue-300;
  accent_secondary_dark = tailwind.blue-400;
  accent_secondary_darker = tailwind.blue-500;
  accent_secondary_darkest = tailwind.blue-600;
  accent_secondary_surface = surface_blue;

  borders = tailwind.zinc-600;
  borders_active = borders;
  borders_inactive = tailwind.zinc-800;
  borders_focused_inactive = tailwind.zinc-700;
  borders_accent = accent_secondary_darker;
  borders_urgent = tailwind.red-400;

  surface_active = tailwind.zinc-600;
  surface_inactive = tailwind.zinc-800;
  surface_focused_inactive = tailwind.zinc-700;
  surface_urgent = tailwind.red-900;

  surface_dark = tailwind.zinc-950;
  surface = tailwind.zinc-900;
  surface_cursorline = tailwind.zinc-800;
  surface_menu = tailwind.zinc-950;
  surface_menu_cursorline = tailwind.zinc-800;

  surface_statusline = tailwind.zinc-800;
  surface_statusline_dim = tailwind.zinc-700;
  surface_statusline_dimmer = tailwind.zinc-600;
  on_surface_statusline = tailwind.zinc-300;
  on_surface_statusline_dim = tailwind.zinc-400;
  on_surface_statusline_dimmer = tailwind.zinc-500;
  on_surface_statusline_dimmest = tailwind.zinc-600;

  surface_scrollbar = blends.surface_lighter;
  surface_scrollbar_thumb = tailwind.zinc-800;

  surface_cursor = accent_dark;
  on_surface_cursor = tailwind.zinc-900;

  surface_visual = tailwind.blue-800;
  on_surface_visual = tailwind.blue-50;

  surface_search = blends.surface_amber;
  on_surface_search = on_surface_amber;

  surface_red = blends.surface_red;
  on_surface_red = tailwind.red-200;

  surface_green = blends.surface_green;
  on_surface_green = tailwind.green-200;

  surface_amber = blends.surface_amber;
  on_surface_amber = tailwind.amber-200;

  surface_blue = blends.surface_blue;
  on_surface_blue = tailwind.blue-200;

  surface_violet = blends.surface_violet;
  on_surface_violet = tailwind.violet-200;

  terminal_color_0 = surface;
  terminal_color_8 = text_dimmer;

  terminal_color_1 = text_red;
  terminal_color_9 = tailwind.red-200;

  terminal_color_2 = text_green;
  terminal_color_10 = tailwind.green-200;

  terminal_color_3 = text_amber;
  terminal_color_11 = tailwind.amber-200;

  terminal_color_4 = text_blue;
  terminal_color_12 = tailwind.blue-200;

  terminal_color_5 = text_fuchsia;
  terminal_color_13 = tailwind.fuchsia-200;

  terminal_color_6 = text_cyan;
  terminal_color_14 = tailwind.cyan-200;

  terminal_color_7 = text;
  terminal_color_15 = tailwind.zinc-100;

  shell_on_surface = text;
  shell_on_surface_variant = text_dim;
  shell_surface = tailwind.zinc-950;
  shell_wallpaper = tailwind.zinc-900;

  UNUSED = others.magenta;
}
