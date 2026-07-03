import qs.components
import qs.config
import qs.hud.notificationcenter as NotificationCenter
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property NotificationCenter.Wrapper wrapper

    readonly property real rounding: Config.theme.hud.notificationCenter.shape
    readonly property bool flatten: wrapper.height < rounding * 2
    readonly property real roundingY: flatten ? wrapper.height / 2 : rounding

    strokeWidth: 0
    fillColor: Config.theme.hud.border.color

    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
    }
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.roundingY * 2
    }
    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
        direction: PathArc.Counterclockwise
    }
    PathLine {
        relativeX: root.wrapper.width - root.rounding * 2
        relativeY: 0
    }
    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
    }
    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height + root.rounding * 2)
    }

    Behavior on fillColor {
        AnimatedColor {}
    }
}
