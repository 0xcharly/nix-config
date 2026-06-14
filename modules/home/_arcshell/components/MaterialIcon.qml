pragma ComponentBehavior: Bound

import qs.config

ArcText {
    property real fill
    property int grade: 0

    style: Config.tokens.system.typography.icon
    font.variableAxes: ({
            FILL: fill.toFixed(1),
            GRAD: grade,
            opsz: fontInfo.pixelSize,
            wght: fontInfo.weight
        })
}
