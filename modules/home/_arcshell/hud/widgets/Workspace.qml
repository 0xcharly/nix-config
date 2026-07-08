pragma ComponentBehavior: Bound

import qs.config
import qs.config.tokens.feature
import qs.components
import qs.services
import QtQuick

ArcRectangle {
    id: root

    required property int index
    required property var modelData

    required property Workspaces parentTheme

    property bool isHovered: false
    property bool needsAttention: false

    readonly property bool isActive: Hypr.isWorkspaceActive(root.modelData)

    readonly property Workspace theme: {
        if (root.needsAttention) {
            root.parentTheme.needsAttention;
        } else if (root.isHovered) {
            root.parentTheme.hovered;
        } else if (root.isActive) {
            root.parentTheme.active;
        } else {
            root.parentTheme.inactive;
        }
    }

    // The active surface is painted by the shared indicator in Workspaces.qml
    // (decoupled so it can slide between items); hovered/needsAttention still
    // paint locally, above the indicator.
    color: root.theme === root.parentTheme.active ? Config.tokens.system.colors.transparent : root.theme.colors.surface
    radius: root.theme.shape

    implicitHeight: layout.implicitHeight
    implicitWidth: layout.implicitWidth

    MouseArea {
        anchors.fill: layout
        hoverEnabled: true

        onClicked: Hypr.goToWorkspace(root.modelData)
        onEntered: root.isHovered = true
        onExited: root.isHovered = false
    }

    ArcText {
        id: layout

        anchors.fill: parent
        bottomPadding: root.theme.padding.bottom
        leftPadding: root.theme.padding.left
        rightPadding: root.theme.padding.right
        topPadding: root.theme.padding.top

        tabularFigures: true
        color: root.theme.colors.content
        style: root.theme.typography
        text: Hypr.getWorkspaceName(root.modelData)
    }
}
