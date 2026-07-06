pragma ComponentBehavior: Bound

import qs.config.tokens.feature as FeatureTokens
import qs.components
import qs.services as ArcServices
import QtQuick
import QtQuick.Effects

// Bar icon reporting whether this host egresses via a Mullvad exit
// node (services/VpnCheck.qml). Glyph+color swaps reuse the
// ArcSliderLabel enter/exit recipe: opacity+scale+blur out, flip
// content while invisible, animate back in.
Item {
    id: root

    required property FeatureTokens.Vpn theme

    readonly property string icon: {
        switch (ArcServices.VpnCheck.status) {
        case "mullvad":
            return "vpn_key";
        case "error":
            return "vpn_key_alert";
        default:
            // "exposed" and startup "unknown".
            return "vpn_key_off";
        }
    }
    readonly property color stateColor: {
        switch (ArcServices.VpnCheck.status) {
        case "mullvad":
            return root.theme.connectedColors.content;
        case "error":
            return root.theme.errorColors.content;
        default:
            return root.theme.colors.content;
        }
    }

    // Rendered glyph/color; refreshed at the animation midpoint so
    // state changes animate instead of snapping. Every status change
    // flips the glyph, so driving the swap off icon alone is enough.
    property string displayedIcon
    property color displayedColor

    implicitWidth: iconLabel.implicitWidth
    implicitHeight: iconLabel.implicitHeight

    onIconChanged: {
        if (!displayedIcon) {
            displayedIcon = icon;
            displayedColor = stateColor;
            return;
        }
        anim.restart();
    }

    Component.onCompleted: {
        if (!displayedIcon) {
            displayedIcon = icon;
            displayedColor = stateColor;
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
                root.displayedIcon = root.icon;
                root.displayedColor = root.stateColor;
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

            anchors.centerIn: parent
            text: root.displayedIcon
            color: root.displayedColor
            fill: 1
            font.pointSize: root.theme.iconSize
        }
    }
}
