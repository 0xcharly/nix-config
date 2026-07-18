pragma ComponentBehavior: Bound

import qs.config.tokens.feature as FeatureTokens
import qs.components
import Quickshell
import Quickshell.Wayland
import QtQuick

Variants {
    id: root

    required property FeatureTokens.Desktop theme

    model: Quickshell.screens

    ArcWindow {
        id: win

        required property ShellScreen modelData

        name: "desktop"
        screen: modelData

        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background

        color: root.theme.colors.surface

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        DesktopLicense {
            id: license
            theme: root.theme.license

            absX: license.x
            absY: license.y

            anchors.left: parent.left
            anchors.bottom: parent.bottom
        }
    }
}
