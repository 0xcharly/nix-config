pragma ComponentBehavior: Bound

import qs.config
import qs.config.tokens.types
import QtQuick

Text {
    id: root

    property TypographyValues style: Config.tokens.system.typography.body

    property bool animate: false
    property string animateProp: "scale"
    property real animateFrom: 0
    property real animateTo: 1
    property int animateDuration: Config.tokens.system.animations.durations.medium
    property bool tabularFigures: false

    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    font.family: style.family
    font.pointSize: style.fontSize
    font.weight: style.weight
    font.underline: style.underline
    font.italic: style.italic
    fontSizeMode: Text.FixedSize
    font.features: {
        "tnum": root.tabularFigures ? 1 : 0
    }
    lineHeight: style.lineHeight
    lineHeightMode: Text.FixedHeight
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
        AnimatedColor {}
    }

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            Anim {
                to: root.animateFrom
                easing.bezierCurve: Config.tokens.system.animations.curves.standardAccel
            }
            PropertyAction {}
            Anim {
                to: root.animateTo
                easing.bezierCurve: Config.tokens.system.animations.curves.standardDecel
            }
        }
    }

    component Anim: AnimatedNumber {
        target: root
        property: root.animateProp
        duration: root.animateDuration / 2
        easing.type: Easing.BezierSpline
    }
}
