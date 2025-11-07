# Effectively implement Sway's "smart_gaps" feature in Hyprland.
{
  wayland.windowManager.hyprland = {
    # Implement "smart gaps" via window and workspace rules.
    settings = {
      windowrulev2 = [
        # https://wiki.hypr.land/Configuring/Workspace-Rules/#smart-gaps
        "bordersize 0, floating:0, onworkspace:w[tv1]"
        "rounding 0, floating:0, onworkspace:w[tv1]"
        "bordersize 0, floating:0, onworkspace:f[1]"
        "rounding 0, floating:0, onworkspace:f[1]"
      ];
      # "smart gaps" cont'd.
      workspace = [
        "w[tv1], gapsout:0, gapsin:0"
        "f[1], gapsout:0, gapsin:0"
      ];
    };
  };
}
