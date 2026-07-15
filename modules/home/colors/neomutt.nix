{ self, ... }:
let
  inherit (self.lib.colors) name;
  colors = self.lib.colors.asHexStrings;
in
{
  flake.homeModules.colors-neomutt =
    { pkgs, ... }:
    let
      content = with colors; ''
        # RGB (#rrggbb) colours require direct-colour support: ncurses must
        # report 16M colours, which only happens under a terminfo entry with
        # the `RGB` capability. The neomutt package is wrapped to force
        # TERM=xterm-direct (see programs-neomutt.nix); keep directcolor
        # explicit rather than relying on terminfo auto-detection.
        set color_directcolor = yes

        # UI chrome
        color normal      ${text}                  default
        color error       ${text_error}            default
        color message     ${text}                  default
        color prompt      ${text_variant}          default
        color status      ${on_surface_statusline} ${surface_statusline}
        color indicator   ${text_title}            ${surface_cursorline}
        color tree        ${text_dimmer}           default
        color markers     ${text_dimmer}           default
        color tilde       ${text_conceal}          default
        color search      ${on_surface_search}     ${surface_search}
        color progress    ${on_surface_statusline} ${surface_statusline_dim}
        color bold        ${text_title}            default
        color underline   ${text_title}            default

        # Sidebar
        color sidebar_divider    ${borders}      default
        color sidebar_ordinary   ${text_dim}     default
        color sidebar_spool_file ${text}         default
        color sidebar_new        ${text_green}   default
        color sidebar_flagged    ${text_amber}   default
        color sidebar_indicator  ${text_title}   ${surface_cursorline}
        color sidebar_highlight  ${accent}       default

        # Index (later pattern wins)
        color index        ${text_dim}     default '.*'
        color index        ${text}         default ~N
        color index        ${text}         default ~O
        color index        ${text_amber}   default ~F
        color index        ${accent}       default ~T
        color index        ${text_red}     default ~D
        color index_date   ${text_dimmer}  default
        color index_number ${text_dimmest} default
        color index_size   ${text_dimmest} default

        # Pager: headers, quotes, body
        color hdrdefault  ${text_dimmer}   default
        color header      ${text_variant}  default '^(From|To|Cc|Bcc|Date):'
        color header      ${text_title}    default '^Subject:'
        color quoted      ${text_green}    default
        color quoted1     ${text_blue}     default
        color quoted2     ${text_purple}   default
        color quoted3     ${text_teal}     default
        color quoted4     ${text_dimmer}   default
        color quoted5     ${text_dimmer}   default
        color signature   ${text_comment}  default
        color attachment  ${text_teal}     default
        color body        ${text_link}     default 'https?://[^ ]+'
      '';
    in
    {
      programs.neomutt.extraConfig = ''
        source ${pkgs.writeText "${name}.neomuttrc" content}
      '';
    };
}
