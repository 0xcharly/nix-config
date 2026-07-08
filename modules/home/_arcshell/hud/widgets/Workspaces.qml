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

    // Delegate of the active workspace, or null while Hyprland settles (e.g.
    // right after switching to a just-created workspace whose delegate has
    // not been instantiated yet).
    readonly property Item activeItem: {
        root.activeWsId;   // re-resolve on focus change
        workspaces.count;  // re-resolve on insert/remove
        for (let i = 0; i < workspaces.count; i++) {
            const item = workspaces.itemAt(i);
            if (item?.isActive)
                return item;
        }
        return null;
    }

    // Last non-null activeItem: holds the indicator in place across the
    // transient nulls above. QML resets object properties to null when the
    // target is destroyed, so a dangling delegate cannot be dereferenced —
    // the indicator just hides until the next resolve.
    property Item currentItem: null

    // First resolve after startup snaps into place instead of gliding in
    // from (0,0). Qt.callLater flips the flag only after the indicator's
    // geometry bindings have settled on the first target.
    property bool indicatorSettled: false

    onActiveItemChanged: {
        if (activeItem) {
            currentItem = activeItem;
            if (!indicatorSettled)
                Qt.callLater(() => root.indicatorSettled = true);
        }
    }

    implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom
    implicitWidth: layout.implicitWidth + root.theme.padding.left + root.theme.padding.right

    Layout.bottomMargin: root.theme.padding.bottom
    Layout.leftMargin: root.theme.padding.left
    Layout.rightMargin: root.theme.padding.right
    Layout.topMargin: root.theme.padding.top

    BufferedWheelEventMouseArea {
        anchors.fill: layout

        function onWheel(event: WheelEvent) {
            if (event.angleDelta.y < 0) {
                Hypr.goToNextOccupiedWorkspace();
            } else if (event.angleDelta.y > 0) {
                Hypr.goToPreviousOccupiedWorkspace();
            }
        }
    }

    // Single shared background behind the active workspace. Declared before
    // the ColumnLayout so delegate surfaces (hover/attention) and labels
    // render on top. Tracks the active delegate's geometry: y slides between
    // workspaces; x/width/height follow because label widths differ (the
    // delegates are AlignHCenter with variable text width).
    ArcRectangle {
        id: indicator

        visible: root.currentItem !== null

        x: layout.x + (root.currentItem?.x ?? 0)
        y: layout.y + (root.currentItem?.y ?? 0)
        width: root.currentItem?.width ?? 0
        height: root.currentItem?.height ?? 0

        color: root.theme.active.colors.surface
        radius: root.theme.active.shape

        Behavior on x {
            enabled: root.indicatorSettled

            AnimatedNumber {
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
        }
        Behavior on y {
            enabled: root.indicatorSettled

            AnimatedNumber {
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
        }
        Behavior on width {
            enabled: root.indicatorSettled

            AnimatedNumber {
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
        }
        Behavior on height {
            enabled: root.indicatorSettled

            AnimatedNumber {
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
        }
    }

    ColumnLayout {
        id: layout
        spacing: root.theme.spacedBy

        anchors.left: parent.left
        anchors.right: parent.right

        Repeater {
            id: workspaces
            // ScriptModel diffs by value identity, so delegates of retained
            // workspaces survive inserts/removals — the indicator's target
            // keeps existing and its y-binding animates the shift. A plain
            // JS-array model would tear down every delegate on each change.
            model: ScriptModel {
                values: Hypr.workspacesFor(root.screen)
            }

            Workspace {
                parentTheme: root.theme
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
