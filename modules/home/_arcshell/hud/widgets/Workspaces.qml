pragma ComponentBehavior: Bound

import qs.config.tokens.feature as FeatureTokens
import qs.components
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

ArcRectangle {
    id: root

    required property ShellScreen screen
    required property FeatureTokens.Workspaces theme

    readonly property int activeWsId: Hypr.monitorFor(screen)?.activeWorkspace?.id ?? 1

    implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom
    implicitWidth: layout.implicitWidth + root.theme.padding.left + root.theme.padding.right

    Layout.bottomMargin: root.theme.padding.bottom
    Layout.leftMargin: root.theme.padding.left
    Layout.rightMargin: root.theme.padding.right
    Layout.topMargin: root.theme.padding.top

    MouseArea {
        anchors.fill: layout

        onWheel: event => {
            if (event.angleDelta.y < 0) {
                Hypr.goToNextOccupiedWorkspace();
            } else if (event.angleDelta.y > 0) {
                Hypr.goToPreviousOccupiedWorkspace();
            }
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: layout
        spacing: root.theme.spacedBy

        anchors.left: parent.left
        anchors.right: parent.right

        Repeater {
            id: workspaces
            model: Hypr.workspacesFor(root.screen)

            Workspace {
                parentTheme: root.theme
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
