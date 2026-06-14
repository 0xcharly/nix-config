import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property SurfaceColorValues colors: SurfaceColorValues {
        surface: Config.tokens.system.colors.wallpaper
        content: Config.tokens.system.colors.on_surface
    }

    property DesktopClock clock: DesktopClock {}
    property DesktopLicense license: DesktopLicense {}
}
