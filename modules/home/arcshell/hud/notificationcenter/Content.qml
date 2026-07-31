pragma ComponentBehavior: Bound

import qs.hud.notificationcenter.widgets
import qs.components
import qs.config
import qs.config.tokens.types
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property ShellScreen screen
    readonly property ThemeConfig.NotificationCenter theme: Config.theme.hud.notificationCenter

    // Rows beyond `maxVisible` collapse into the "x others" line; the
    // service list is newest-first.
    readonly property int overflow: Math.max(0, Notifications.notClosed.length - root.theme.maxVisible)

    implicitWidth: layout.implicitWidth + root.theme.padding.left + root.theme.padding.right - Config.theme.hud.border.width
    implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom

    color: Config.theme.hud.border.color

    Behavior on color {
        AnimatedColor {}
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.bottomMargin: root.theme.padding.bottom
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: root.theme.padding.top
        spacing: Config.theme.hud.notificationCenter.spacedBy

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.theme.padding.left
            Layout.rightMargin: root.theme.padding.right
            spacing: Config.theme.hud.notificationCenter.spacedBy

            ArcText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Config.tokens.system.colors.on_surface
                style: Config.tokens.system.typography.mediumTitle
                text: qsTr("Notification Center")
            }

            // "Clear all" — an interfaces.dev-style "shadow" pill: the ring
            // is a translucent wash of the content color instead of a solid
            // border (their dark chrome is `box-shadow: 0 0 0 1px #ffffff14`),
            // so it reads as depth on any backdrop.
            ArcRectangle {
                id: clearAll

                // Accent normally; the alt accent while an urgent
                // notification is pinned in the list below.
                readonly property SurfaceColorValues badge: Notifications.hasUrgent ? root.theme.accentAlt : root.theme.accent

                visible: Notifications.notClosed.length > 0
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: clearAllRow.implicitWidth + Config.tokens.system.measurements.small + Config.tokens.system.measurements.medium
                implicitHeight: clearAllRow.implicitHeight + 2 * Config.tokens.system.measurements.small
                radius: height / 2
                color: clearAllArea.containsMouse ? Config.tokens.system.colors.surface_backdrop : Config.tokens.system.colors.transparent
                border.width: 1
                border.color: Qt.alpha(Config.tokens.system.colors.on_surface, 0.08)
                // Press feedback: sink the whole pill.
                scale: clearAllArea.pressed ? 0.9 : 1

                Behavior on scale {
                    AnimatedNumber {
                        duration: Config.tokens.system.animations.durations.small
                    }
                }

                RowLayout {
                    id: clearAllRow

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Config.tokens.system.measurements.small
                    spacing: Config.tokens.system.measurements.small

                    // Same disc as the collapsed count badge (Wrapper.qml):
                    // a bright `on_surface_*` core carrying the glyph in
                    // `surface_*`, wrapped in a `surface_*` rim.
                    ArcRectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: implicitHeight
                        implicitHeight: root.theme.clearAllBadgeSize
                        radius: height / 2
                        color: clearAll.badge.surface

                        ArcRectangle {
                            anchors.fill: parent
                            anchors.margins: root.theme.badgeRim
                            radius: height / 2
                            color: clearAll.badge.content
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            color: clearAll.badge.surface
                            font.pointSize: Config.tokens.system.typography.mediumLabel.fontSize
                            lineHeight: Config.tokens.system.typography.mediumLabel.lineHeight
                            text: "check"
                        }
                    }

                    ArcText {
                        Layout.alignment: Qt.AlignVCenter
                        color: Config.tokens.system.colors.on_surface
                        style: Config.tokens.system.typography.smallTitle
                        text: qsTr("Clear all")
                    }
                }

                MouseArea {
                    id: clearAllArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.clear()
                }
            }
        }

        Repeater {
            model: ScriptModel {
                // notClosed is a QQmlListReference (list<> property); ScriptModel
                // wants a QVariantList, so materialize a plain JS array.
                values: Array.from(Notifications.notClosed)
            }

            Notification {}
        }

        ArcText {
            visible: Notifications.notClosed.length === 0
            Layout.fillWidth: true
            Layout.topMargin: Config.tokens.system.measurements.medium
            Layout.bottomMargin: Config.tokens.system.measurements.medium
            horizontalAlignment: Text.AlignHCenter
            color: Config.tokens.system.colors.on_surface_variant
            style: Config.tokens.system.typography.body
            text: qsTr("No notifications.")
        }

        ArcText {
            visible: root.overflow > 0
            Layout.fillWidth: true
            Layout.leftMargin: root.theme.padding.left
            Layout.rightMargin: root.theme.padding.right
            horizontalAlignment: Text.AlignHCenter
            color: Config.tokens.system.colors.on_surface_variant
            style: Config.tokens.system.typography.smallLabel
            text: root.overflow === 1 ? qsTr("1 other") : qsTr("%1 others").arg(root.overflow)
        }
    }
}
