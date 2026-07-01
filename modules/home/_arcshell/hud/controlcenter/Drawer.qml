import qs.components
import qs.config
import qs.hud.controlcenter as ControlCenter
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property ControlCenter.Wrapper wrapper

    readonly property real rounding: Config.theme.hud.controlCenter.shape
    readonly property bool flatten: wrapper.height < rounding * 2
    readonly property real roundingY: flatten ? wrapper.height / 2 : rounding

    strokeWidth: 0
    fillColor: Config.theme.hud.border.color

    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height + root.roundingY)
    }
    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: root.roundingY
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
        radiusY: root.roundingY
    }
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.roundingY * 2
    }
    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: root.roundingY
        direction: PathArc.Counterclockwise
    }

    Behavior on fillColor {
        AnimatedColor {}
    }
}
