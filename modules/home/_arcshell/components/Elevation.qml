import qs.config
import QtQuick
import QtQuick.Effects

RectangularShadow {
    property int level
    property real dp: [0, 1, 3, 6, 8, 12][level]

    color: Config.theme.hud.innerBorderShadow
    blur: (dp * 5) ** 0.7
    spread: -dp * 0.3 + (dp * 0.1) ** 2
    offset.y: dp / 2

    Behavior on dp {
        AnimatedNumber {}
    }
}
