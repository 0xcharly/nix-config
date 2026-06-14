import qs.config
import QtQuick

NumberAnimation {
    duration: 200
    easing.type: Easing.BezierSpline
    easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
}
