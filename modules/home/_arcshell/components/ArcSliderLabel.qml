pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.config
import qs.config.tokens.component as ComponentTokens

// Reusable slider readout: shows a material icon when idle and the
// current value as a zero-padded percentage ("05", "38", "100") while
// the value changes, reverting theme.timeout ms after the last
// change. State swaps and idle glyph changes animate opacity+scale+
// blur out, flip content while invisible, then animate back in
// (https://www.interfaces.dev enter/exit recipe). Value changes while
// the digits are already shown update live, unanimated.
Item {
    id: root

    // Value in slider units where 1.0 == 100%.
    required property real value
    // Material symbol name shown when idle.
    required property string icon
    // Keeps the value shown while the slider is held down.
    property bool held: false
    // Icon/text color; consumers pair it with their slider's accent.
    property color color: theme.color

    property ComponentTokens.SliderLabel theme: Config.tokens.component.sliderLabel

    // Desired state; flips immediately when the value changes/settles.
    property bool showingValue: false
    // Displayed state; flips at the animation midpoint.
    property bool displayingValue: false
    // Rendered glyph; refreshed at animation midpoints so glyph
    // changes while the icon is visible animate instead of snapping.
    property string displayedIcon
    property real oldValue
    property bool initialized

    implicitWidth: Math.max(sizer.implicitWidth, iconLabel.implicitWidth)
    implicitHeight: Math.max(sizer.implicitHeight, iconLabel.implicitHeight)

    onValueChanged: {
        if (!initialized) {
            initialized = true;
            return;
        }
        if (Math.abs(value - oldValue) < 0.01) {
            return;
        }
        oldValue = value;
        showingValue = true;
        revert.restart();
    }

    onIconChanged: {
        if (!displayedIcon) {
            displayedIcon = icon;
            return;
        }
        if (displayingValue || showingValue) {
            // Glyph hidden (or about to hide): swap silently; the
            // midpoint refresh covers the return transition.
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

    onHeldChanged: {
        if (held) {
            showingValue = true;
        } else {
            revert.restart();
        }
    }

    onShowingValueChanged: anim.restart()

    Timer {
        id: revert

        interval: root.theme.timeout
        onTriggered: {
            if (!root.held) {
                root.showingValue = false;
            }
        }
    }

    SequentialAnimation {
        id: anim

        ParallelAnimation {
            AnimatedNumber {
                target: content
                property: "opacity"
                to: 0
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
            AnimatedNumber {
                target: content
                property: "scale"
                to: 0.25
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
            AnimatedNumber {
                target: content
                property: "blurAmount"
                to: 1
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
        }
        ScriptAction {
            script: {
                root.displayingValue = root.showingValue;
                root.displayedIcon = root.icon;
            }
        }
        ParallelAnimation {
            AnimatedNumber {
                target: content
                property: "opacity"
                to: 1
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveOut
            }
            AnimatedNumber {
                target: content
                property: "scale"
                to: 1
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveOut
            }
            AnimatedNumber {
                target: content
                property: "blurAmount"
                to: 0
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveOut
            }
        }
    }

    Item {
        id: content

        // Normalized blur driven by the swap animation; ~4px visible
        // blur mid-transition (blurMax 8 x blur 0.5).
        property real blurAmount: 0

        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: content.blurAmount
            blurMax: 8
        }

        MaterialIcon {
            id: iconLabel

            visible: !root.displayingValue
            anchors.centerIn: parent
            text: root.displayedIcon
            color: root.color
        }

        ArcText {
            id: valueLabel

            visible: root.displayingValue
            anchors.centerIn: parent
            style: root.theme.typography
            font.variableAxes: ({
                    ROND: root.theme.typography.roundness,
                    wght: root.theme.typography.weight
                })
            text: String(Math.round(root.value * 100)).padStart(2, "0")
            color: root.color
        }
    }

    // Invisible sizer pinning the slot width to the widest value.
    ArcText {
        id: sizer

        visible: false
        style: root.theme.typography
        font.variableAxes: ({
                ROND: root.theme.typography.roundness,
                wght: root.theme.typography.weight
            })
        text: "100"
    }
}
