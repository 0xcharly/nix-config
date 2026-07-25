pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.config
import qs.config.tokens.types

// Material icon whose glyph changes run the dynamic island's combined
// opacity+scale+blur swap (ArcSliderLabel's enter/exit recipe,
// https://www.interfaces.dev): fade+shrink+blur out, swap the glyph
// while invisible, then reverse back in.
Item {
    id: root

    // Material symbol name; changes animate, first assignment renders
    // directly.
    required property string icon
    property real fill
    property int grade: 0
    property color color: Config.tokens.system.colors.on_surface
    property TypographyValues style: Config.tokens.system.typography.icon
    property AnimationValues animation: AnimationValues {}

    // Rendered glyph; swapped at the animation midpoint.
    property string displayedIcon

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    onIconChanged: {
        if (!displayedIcon) {
            displayedIcon = icon;
            return;
        }
        anim.restart();
    }

    Component.onCompleted: {
        if (!displayedIcon) {
            displayedIcon = icon;
        }
    }

    SequentialAnimation {
        id: anim

        ParallelAnimation {
            AnimatedNumber {
                target: content
                property: "opacity"
                to: 0
                duration: root.animation.duration
                easing.bezierCurve: root.animation.curveIn
            }
            AnimatedNumber {
                target: content
                property: "scale"
                to: 0.25
                duration: root.animation.duration
                easing.bezierCurve: root.animation.curveIn
            }
            AnimatedNumber {
                target: content
                property: "blurAmount"
                to: 1
                duration: root.animation.duration
                easing.bezierCurve: root.animation.curveIn
            }
        }
        ScriptAction {
            script: root.displayedIcon = root.icon
        }
        ParallelAnimation {
            AnimatedNumber {
                target: content
                property: "opacity"
                to: 1
                duration: root.animation.duration
                easing.bezierCurve: root.animation.curveOut
            }
            AnimatedNumber {
                target: content
                property: "scale"
                to: 1
                duration: root.animation.duration
                easing.bezierCurve: root.animation.curveOut
            }
            AnimatedNumber {
                target: content
                property: "blurAmount"
                to: 0
                duration: root.animation.duration
                easing.bezierCurve: root.animation.curveOut
            }
        }
    }

    Item {
        id: content

        // Normalized blur driven by the swap animation; ~4px visible
        // blur mid-transition (blurMax 8 x blur 0.5).
        property real blurAmount: 0

        anchors.fill: parent
        // Layered only while swapping: blur is zero at rest, so the
        // offscreen buffer would cost GPU memory for nothing.
        layer.enabled: anim.running
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: content.blurAmount
            blurMax: 8
        }

        MaterialIcon {
            id: label

            anchors.centerIn: parent
            text: root.displayedIcon
            fill: root.fill
            grade: root.grade
            color: root.color
            style: root.style
        }
    }
}
