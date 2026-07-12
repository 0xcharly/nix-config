pragma ComponentBehavior: Bound

import qs.components
import qs.config.tokens.feature as FeatureTokens
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects

// Bar icon mirroring the current power profile. Same glyphs as the
// launcher command palette (services/CommandSearch.qml). Glyph swaps
// reuse the ArcSliderLabel enter/exit recipe: opacity+scale+blur out,
// flip content while invisible, animate back in.
Item {
    id: root

    required property FeatureTokens.PowerProfile theme

    readonly property string icon: {
        if (PowerProfiles.profile === PowerProfile.PowerSaver)
            return "energy_savings_leaf";
        if (PowerProfiles.profile === PowerProfile.Performance)
            return "speed";
        return "balance";
    }

    // Rendered glyph; refreshed at the animation midpoint so profile
    // changes animate instead of snapping.
    property string displayedIcon

    implicitWidth: iconLabel.implicitWidth
    implicitHeight: iconLabel.implicitHeight

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
            script: root.displayedIcon = root.icon
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

            anchors.centerIn: parent
            text: root.displayedIcon
            color: root.theme.colors.content
            fill: 1
            font.pointSize: root.theme.iconSize
        }
    }
}
