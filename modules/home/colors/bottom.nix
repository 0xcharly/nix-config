# Theme inspired from https://github.com/catppuccin/bottom
# MIT License: Copyright (c) 2021 Catppuccin

{ self, ... }:
let
  colors = self.lib.colors.asHexStrings;
in
{
  flake.homeModules.colors-bottom = {
    programs.bottom.settings = with colors; {
      "styles.cpu" = {
        all_entry_color = text_rose;
        avg_entry_color = text_pink;
        cpu_core_colors = [
          text_red
          text_orange
          text_amber
          text_green
          text_blue
          text_violet
        ];
      };
      "styles.memory" = {
        ram_color = text_green;
        cache_color = text_red;
        swap_color = text_orange;
        gpu_colors = [
          text_blue
          text_violet
          text_red
          text_orange
          text_amber
          text_green
        ];
        arc_color = text_cyan;
      };
      "styles.network" = {
        rx_color = text_green;
        tx_color = text_red;
        rx_total_color = text_cyan;
        tx_total_color = text_green;
      };
      "styles.battery" = {
        high_battery_color = text_green;
        medium_battery_color = text_amber;
        low_battery_color = text_red;
      };
      "styles.tables" = {
        headers.color = text_rose;
      };
      "styles.graphs" = {
        graph_color = borders;
        legend_text.color = text_comment;
      };
      "styles.widgets" = {
        border_color = borders;
        selected_border_color = text_pink;
        widget_title.color = text_rose;
        text.color = text;
        selected_text = {
          color = on_surface_visual;
          bg_color = surface_visual;
        };
        disabled_text.color = text_variant_dimmer;
      };
    };
  };
}
