let
  signs = (import ./common.nix).diagnostic_signs;
  lualine_groups_generator = suffix: {
    a = "LualineA" + suffix;
    b = "LualineB" + suffix;
    c = "LualineC" + suffix;
    x = "LualineX" + suffix;
    y = "LualineY" + suffix;
    z = "LualineZ" + suffix;
  };
  section_filename = {
    name = "filename";
    extraConfig = {
      symbols = {
        modified = "󱇨 "; # Text to show when the file is modified.
        readonly = "󱀰 "; # Text to show when the file is non-modifiable or readonly.
        unnamed = "󰡯 ";  # Text to show for unnamed buffers.
        newfile = "󰻭 ";  # Text to show for newly created file before first write
      };
    };
  };
in {
  enable = true;
  theme = {
    normal = lualine_groups_generator "Normal";
    insert = lualine_groups_generator "Insert";
    visual = lualine_groups_generator "Visual";
    replace = lualine_groups_generator "Replace";
    command = lualine_groups_generator "Command";
    inactive = lualine_groups_generator "Inactive";
  };
  sections = {
    lualine_a = [ "mode" ];
    lualine_b = [ section_filename ];
    lualine_c = [
      {
        name = "lsp_info";
        separator = { left = "‥"; right = ""; };
      }
      {
        name = "diagnostics";
        extraConfig = {
          symbols = {
            error = signs.error;
            warn = signs.warn;
            info = signs.info;
            hint = signs.hint;
          };
        };
      }
    ];
    lualine_x = [
      {
        name = "diff";
        separator = { left = "‥"; right = ""; };
        extraConfig = {
          symbols = { added = "󱍭 "; modified = "󱨈 "; removed = "󱍪 "; };
        };
      }
      {
        name = "branch";
        icon = { icon = ""; align = "right"; };
      }
    ];
    lualine_y = [ "progress" ];
    lualine_z = [ "location" ];
  };
  inactiveSections = {
    lualine_a = [ "mode" ];
    lualine_b = null;
    lualine_c = [ section_filename ];
    lualine_x = [ "location" ];
    lualine_y = null;
    lualine_z = null;
  };
}
