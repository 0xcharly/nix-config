pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.config.tokens.component as ComponentTokens
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Effects
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
        // the right edge for a plain middle-click (x still 0).
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

        color: root.modelData.urgency === NotificationUrgency.Critical ? root.theme.surfaceCritical.surface : root.theme.surface.colors.surface
        radius: root.theme.surface.shape
        // Fade with the reveal state and as the card slides toward dismissal.
        opacity: root.reveal * (1 - Math.abs(x) / width)

        Behavior on implicitHeight {
            // Animate expand/collapse only. During the initial reveal (and the
            // dismiss collapse) the root's `reveal` Behavior owns the height —
            // enabling this one there would double-animate.
            enabled: root.reveal === 1

            PropAnim {}
        }

        // Declared before `layout` so the interactive items inside it
        // (chevron, action buttons) sit above the drag area; text items
        // don't accept mouse events, so presses elsewhere still fall
        // through to it.
        MouseArea {
            id: dragArea

            // Drag-down on a collapsed card expands it. Guard `expandedByDrag`:
            // a right-button drag-down would otherwise expand via positionChanged
            // and immediately collapse again via the same press's clicked event.
            property real pressY: 0
            property bool expandedByDrag: false

            anchors.fill: parent
            enabled: root.shown && !dismissAnim.running
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            drag.target: card
            drag.axis: Drag.XAxis

            onPressed: mouse => {
                pressY = mouse.y;
                expandedByDrag = false;
            }
            onPositionChanged: mouse => {
                if (!root.modelData.expanded && mouse.y - pressY > root.theme.expandDragThreshold) {
                    root.modelData.expanded = true;
                    expandedByDrag = true;
                }
            }
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton)
                    root.dismiss();
                else if (mouse.button === Qt.RightButton && !expandedByDrag)
                    root.modelData.expanded = !root.modelData.expanded;
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

        ColumnLayout {
            id: layout

            // Top + sides only, never bottom: while the expand/collapse
            // Behavior animates the card height, the body has already
            // snapped to its target line count — filling the card would
            // let the ColumnLayout center that short content in the
            // surplus height and make it jump mid-animation.
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
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

                // Expand/collapse chevron. MaterialIcon's default icon typography and
                // the timestamp color keep it visually paired with the timestamp.
                // Glyph swaps follow the ArcSliderLabel recipe: fade+shrink+blur out,
                // flip the glyph while invisible, animate back in.
                Item {
                    id: chevron

                    // Rendered direction; flips at the animation midpoint. Deliberately
                    // NOT a binding: the ScriptAction below owns updates after init.
                    property bool displayedExpanded: root.modelData.expanded

                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: chevronIcon.implicitWidth
                    implicitHeight: chevronIcon.implicitHeight

                    Connections {
                        target: root.modelData

                        function onExpandedChanged(): void {
                            chevronAnim.restart();
                        }
                    }

                    SequentialAnimation {
                        id: chevronAnim

                        ParallelAnimation {
                            AnimatedNumber {
                                target: chevronContent
                                property: "opacity"
                                to: 0
                                duration: root.theme.animation.duration
                                easing.bezierCurve: root.theme.animation.curveIn
                            }
                            AnimatedNumber {
                                target: chevronContent
                                property: "scale"
                                to: 0.25
                                duration: root.theme.animation.duration
                                easing.bezierCurve: root.theme.animation.curveIn
                            }
                            AnimatedNumber {
                                target: chevronContent
                                property: "blurAmount"
                                to: 1
                                duration: root.theme.animation.duration
                                easing.bezierCurve: root.theme.animation.curveIn
                            }
                        }
                        ScriptAction {
                            script: chevron.displayedExpanded = root.modelData.expanded
                        }
                        ParallelAnimation {
                            AnimatedNumber {
                                target: chevronContent
                                property: "opacity"
                                to: 1
                                duration: root.theme.animation.duration
                                easing.bezierCurve: root.theme.animation.curveOut
                            }
                            AnimatedNumber {
                                target: chevronContent
                                property: "scale"
                                to: 1
                                duration: root.theme.animation.duration
                                easing.bezierCurve: root.theme.animation.curveOut
                            }
                            AnimatedNumber {
                                target: chevronContent
                                property: "blurAmount"
                                to: 0
                                duration: root.theme.animation.duration
                                easing.bezierCurve: root.theme.animation.curveOut
                            }
                        }
                    }

                    Item {
                        id: chevronContent

                        // Normalized blur driven by the swap animation; ~4px visible
                        // blur mid-transition (blurMax 8 x blur 0.5).
                        property real blurAmount: 0

                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: chevronContent.blurAmount
                            blurMax: 8
                        }

                        MaterialIcon {
                            id: chevronIcon

                            anchors.centerIn: parent
                            text: chevron.displayedExpanded ? "expand_less" : "expand_more"
                            color: root.theme.timestampContentColor
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        // Enlarge the hit target beyond the glyph.
                        anchors.margins: -Config.tokens.system.measurements.small
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modelData.expanded = !root.modelData.expanded
                    }
                }
            }

            ArcText {
                Layout.fillWidth: true
                visible: text !== ""
                wrapMode: Text.Wrap
                // INT_MAX: Text has no "unset" for maximumLineCount in a binding.
                maximumLineCount: root.modelData.expanded ? 2147483647 : root.theme.bodyMaxLines
                elide: root.modelData.expanded ? Text.ElideNone : Text.ElideRight
                color: root.theme.surface.colors.content
                style: root.theme.surface.typography
                text: root.modelData.body
            }

            // Actions as a wrapping button row, only while expanded. invoke()
            // auto-dismisses non-resident notifications server-side; the tracked
            // wrapper's onClosed connection then removes the row — never call
            // close() here as well.
            Flow {
                Layout.fillWidth: true
                visible: root.modelData.expanded && (root.modelData.notification?.actions.length ?? 0) > 0
                spacing: root.theme.horizontalSpacing

                Repeater {
                    model: root.modelData.notification?.actions ?? []

                    ArcChip {
                        id: actionChip

                        required property var modelData
                        text: modelData.text || modelData.identifier

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: actionChip.modelData.invoke()
                        }
                    }
                }
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
