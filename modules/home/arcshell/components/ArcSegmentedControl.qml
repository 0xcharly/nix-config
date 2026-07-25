pragma ComponentBehavior: Bound

import qs.config
import qs.config.tokens.component as ComponentTokens
import QtQuick
import QtQuick.Layouts

// macOS-style segmented control: equal-width segments inside a pill
// container, one shared selector surface sliding behind the active
// segment (same indicator recipe as hud/widgets/Workspaces.qml).
// `currentIndex` is caller-owned state: clicking only emits activated(),
// the caller decides whether/when the selection actually moves.
Rectangle {
    id: root

    property ComponentTokens.SegmentedControl theme: Config.tokens.component.segmentedControl
    // Array of { icon: string (Material Symbols name), label: string }.
    property var model: []
    property int currentIndex: 0

    signal activated(int index)

    radius: root.theme.shape
    color: root.theme.colors.surface

    implicitWidth: layout.implicitWidth + 2 * root.theme.selectorPadding
    implicitHeight: layout.implicitHeight + 2 * root.theme.selectorPadding

    // Delegate of the selected segment. Depends on count so it re-resolves
    // once the Repeater has instantiated its delegates.
    readonly property Item currentItem: {
        segments.count;
        return segments.itemAt(root.currentIndex);
    }

    // First resolve snaps into place instead of gliding in from (0,0)
    // (same trick as the workspaces indicator).
    property bool selectorSettled: false
    onCurrentItemChanged: {
        if (currentItem && !selectorSettled)
            Qt.callLater(() => root.selectorSettled = true);
    }

    // Selector: declared before the layout so segment content renders on top.
    ArcRectangle {
        visible: root.currentItem !== null

        x: layout.x + (root.currentItem?.x ?? 0)
        y: layout.y + (root.currentItem?.y ?? 0)
        width: root.currentItem?.width ?? 0
        height: root.currentItem?.height ?? 0

        radius: root.theme.selectorShape
        color: root.theme.selected.surface

        Behavior on x {
            enabled: root.selectorSettled

            AnimatedNumber {
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
        }
        Behavior on width {
            enabled: root.selectorSettled

            AnimatedNumber {
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
        }
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: root.theme.selectorPadding
        spacing: root.theme.spacing

        Repeater {
            id: segments

            model: root.model

            Item {
                id: segment

                required property int index
                required property var modelData

                readonly property bool selected: root.currentIndex === segment.index

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitWidth: content.implicitWidth + root.theme.segmentPadding.left + root.theme.segmentPadding.right
                implicitHeight: content.implicitHeight + root.theme.segmentPadding.top + root.theme.segmentPadding.bottom

                // Hover: a hoverLayer surface stacked over the segment
                // (alphas combine with the container), with the exact
                // geometry the selector would have on this segment — the
                // layout already insets segments by selectorPadding. The
                // selected segment carries the selector pill, so hover is
                // suppressed there.
                Rectangle {
                    anchors.fill: parent
                    radius: root.theme.selectorShape
                    color: root.theme.hoverLayer
                    opacity: mouse.containsMouse && !segment.selected ? 1 : 0

                    Behavior on opacity {
                        AnimatedNumber {
                            duration: root.theme.animation.duration
                            easing.bezierCurve: root.theme.animation.curveIn
                        }
                    }
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activated(segment.index)
                }

                // Vertically centered icon + label row.
                RowLayout {
                    id: content

                    anchors.centerIn: parent
                    spacing: root.theme.segmentSpacing

                    AnimatedMaterialIcon {
                        Layout.alignment: Qt.AlignVCenter
                        icon: segment.modelData.icon
                        style: root.theme.iconTypography
                        fill: segment.selected ? 1 : 0
                        color: segment.selected ? root.theme.selected.content : root.theme.colors.content
                        animation: root.theme.animation
                    }

                    ArcText {
                        Layout.alignment: Qt.AlignVCenter
                        text: segment.modelData.label
                        style: root.theme.typography
                        color: segment.selected ? root.theme.selected.content : root.theme.colors.content
                    }
                }
            }
        }
    }
}
