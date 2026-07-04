pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.config.tokens.component as ComponentTokens
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Tracked notification from Notifications.list: summary, body, timeStr,
    // close(). Repeater-injected.
    required property var modelData
    required property int index
    property ComponentTokens.Notification theme: Config.theme.defaults.notifications

    // True while the dismiss sequence (slide-off, then collapse) runs; drops
    // the row out of `shown` so the reveal Behavior collapses its height.
    property bool dismissing: false
    // Rows pushed past maxVisible collapse into the "x others" line. When a
    // shown row is dismissed, the first overflow row re-enters `shown` and
    // the same reveal Behavior grows it back in.
    readonly property bool shown: !dismissing && index < Config.theme.hud.notificationCenter.maxVisible

    // 0 = collapsed/transparent, 1 = fully shown. The binding is installed
    // after creation (same pattern as the Wrapper's Loader.active) so the
    // initial 0 -> 1 change animates: a new row grows in and pushes the
    // rows below it down.
    property real reveal: 0
    Component.onCompleted: reveal = Qt.binding(() => root.shown ? 1 : 0)

    Layout.fillWidth: true
    implicitHeight: reveal * card.implicitHeight
    // A fully collapsed row must leave the layout flow, or every hidden
    // overflow row would keep a permanent ColumnLayout spacing slot.
    visible: reveal > 0
    // Keep the card inside the row while it slides during drags/dismissal.
    clip: true

    function dismiss(): void {
        // Capture the exit edge once: the side the drag was headed for, or
        // the right edge for a plain right-click (x still 0).
        dismissSlide.to = card.x < 0 ? -card.width : card.width;
        dismissAnim.restart();
    }

    Behavior on reveal {
        PropAnim {}
    }

    SequentialAnimation {
        id: dismissAnim

        PropAnim {
            id: dismissSlide

            target: card
            property: "x"
            easing.bezierCurve: root.theme.animation.curveOut
        }
        PropertyAction {
            target: root
            property: "dismissing"
            value: true
        }
        // Covers the reveal Behavior's height collapse, which runs for the
        // themed animation duration.
        PauseAnimation {
            duration: root.theme.animation.duration + 50
        }
        ScriptAction {
            script: root.modelData.close()
        }
    }

    Rectangle {
        id: card

        width: root.width
        implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom

        color: root.theme.surface.colors.surface
        radius: root.theme.surface.shape
        // Fade with the reveal state and as the card slides toward dismissal.
        opacity: root.reveal * (1 - Math.abs(x) / width)

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.bottomMargin: root.theme.padding.bottom
            anchors.leftMargin: root.theme.padding.left
            anchors.rightMargin: root.theme.padding.right
            anchors.topMargin: root.theme.padding.top
            spacing: root.theme.verticalSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: root.theme.horizontalSpacing

                ArcText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    elide: Text.ElideRight
                    color: root.theme.titleContentColor
                    style: root.theme.titleTypography
                    text: root.modelData.summary
                }

                // Relative arrival time; self-refreshing (wrapper timer).
                // Never elided: the title is the only shrinkable row item.
                ArcText {
                    Layout.alignment: Qt.AlignVCenter
                    color: root.theme.timestampContentColor
                    style: root.theme.timestampTypography
                    text: root.modelData.timeStr
                }
            }

            ArcText {
                Layout.fillWidth: true
                visible: text !== ""
                wrapMode: Text.Wrap
                maximumLineCount: root.theme.bodyMaxLines
                elide: Text.ElideRight
                color: root.theme.surface.colors.content
                style: root.theme.surface.typography
                text: root.modelData.body
            }
        }

        MouseArea {
            id: dragArea

            anchors.fill: parent
            enabled: root.shown && !dismissAnim.running
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            drag.target: card
            drag.axis: Drag.XAxis

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.dismiss();
            }
            // Swipe: past a third of the card's width in either direction
            // dismisses; anything less springs back.
            onReleased: {
                if (Math.abs(card.x) > card.width / 3)
                    root.dismiss();
                else
                    card.x = 0;
            }
        }

        Behavior on x {
            // Animate only the spring-back; never fight the active drag or
            // the dismiss slide.
            enabled: !dragArea.drag.active && !dismissAnim.running

            PropAnim {}
        }
    }

    // Themed motion primitive: notification animations follow the component
    // animation tokens (same pattern as ArcSwitch/QuickToggle).
    component PropAnim: NumberAnimation {
        duration: root.theme.animation.duration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: root.theme.animation.curveIn
    }
}
