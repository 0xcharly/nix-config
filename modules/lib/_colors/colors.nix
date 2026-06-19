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

  text_variant = tailwind.gray-300;
  text_variant_dim = tailwind.gray-400;
  text_variant_dimmer = tailwind.gray-500;
  text_variant_dimmest = tailwind.gray-600;
  text_variant_conceal = tailwind.gray-700;

  text_red = tailwind.red-200;
  text_orange = tailwind.orange-100;
  text_amber = tailwind.amber-100;
  text_yellow = tailwind.yellow-50;
  text_lime = tailwind.lime-200;
  text_green = tailwind.green-200;
  text_emerald = tailwind.emerald-200;
  text_teal = tailwind.teal-300;
  text_cyan = tailwind.cyan-200;
  text_sky = tailwind.sky-300;
  text_blue = tailwind.blue-300;
  text_indigo = tailwind.indigo-200;
  text_violet = tailwind.violet-200;
  text_purple = tailwind.purple-200;
  text_fuchsia = tailwind.fuchsia-200;
  text_pink = tailwind.pink-200;
  text_rose = tailwind.rose-200;

  text_title = tailwind.slate-100;
  text_link = tailwind.blue-300;
  text_function = tailwind.blue-300;
  text_comment = text_variant_dimmer;

  text_ok = tailwind.green-200;
  text_error = tailwind.red-200;
  text_warning = tailwind.amber-100;
  text_info = tailwind.blue-300;
  text_hint = tailwind.indigo-300;

  text_lineno = tailwind.zinc-700;
  text_lineno_cursor = tailwind.zinc-400;

  accent = tailwind.violet-200;
  accent_dark = tailwind.violet-300;
  accent_darker = tailwind.violet-400;
  accent_darkest = tailwind.violet-500;

  accent_secondary = tailwind.sky-200;
  accent_secondary_dark = tailwind.sky-300;
  accent_secondary_darker = tailwind.sky-400;
  accent_secondary_darkest = tailwind.sky-500;

  borders = tailwind.slate-500;
  borders_active = tailwind.amber-400;
  borders_inactive = tailwind.sky-400;
  borders_focused_inactive = tailwind.violet-400;
  borders_urgent = tailwind.red-400;
  borders_desktop_shell = tailwind.violet-400;

  shadows = tailwind.slate-950;
  shadows_active = tailwind.amber-600;
  shadows_inactive = tailwind.blue-600;
  shadows_focused_inactive = tailwind.violet-600;
  shadows_urgent = tailwind.red-600;
  shadows_desktop_shell = tailwind.violet-600;

  surface_active = tailwind.amber-900;
  surface_inactive = tailwind.blue-900;
  surface_focused_inactive = tailwind.violet-900;
  surface_urgent = tailwind.red-900;

  surface_dark = tailwind.neutral-950;
  surface = tailwind.neutral-900;
  surface_cursorline = tailwind.neutral-800;
  surface_menu = tailwind.stone-900;
  surface_menu_cursorline = tailwind.stone-800;

  surface_statusline = tailwind.zinc-800;
  surface_statusline_dim = tailwind.zinc-700;
  surface_statusline_dimmer = tailwind.zinc-600;
  on_surface_statusline = tailwind.zinc-300;
  on_surface_statusline_dim = tailwind.zinc-400;
  on_surface_statusline_dimmer = tailwind.zinc-500;
  on_surface_statusline_dimmest = tailwind.zinc-600;

  surface_scrollbar = blends.surface_lighter;
  surface_scrollbar_thumb = tailwind.neutral-800;

  surface_cursor = tailwind.violet-400;
  on_surface_cursor = tailwind.neutral-900;

  surface_visual = tailwind.blue-800;
  on_surface_visual = tailwind.blue-50;

  surface_search = blends.surface_amber;
  on_surface_search = tailwind.amber-100;

  surface_red = blends.surface_red;
  on_surface_red = tailwind.red-200;

  surface_green = blends.surface_green;
  on_surface_green = tailwind.green-200;

  surface_amber = blends.surface_amber;
  on_surface_amber = tailwind.amber-100;

  surface_blue = blends.surface_blue;
  on_surface_blue = tailwind.blue-300;

  surface_violet = blends.surface_violet;
  on_surface_violet = tailwind.violet-200;

  terminal_color_0 = surface;
  terminal_color_8 = text_dimmer;

  terminal_color_1 = text_red;
  terminal_color_9 = text_red;

  terminal_color_2 = text_green;
  terminal_color_10 = text_green;

  terminal_color_3 = text_amber;
  terminal_color_11 = text_amber;

  terminal_color_4 = text_blue;
  terminal_color_12 = text_blue;

  terminal_color_13 = text_sky;
  terminal_color_5 = text_sky;

  terminal_color_6 = tailwind.violet-300;
  terminal_color_14 = tailwind.violet-300;

  terminal_color_7 = text;
  terminal_color_15 = text_dim;

  UNUSED = others.magenta;
}
