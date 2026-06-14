pragma ComponentBehavior: Bound

import qs.components
import qs.config
import Quickshell
import QtQuick

Scope {
    id: root

    required property ShellScreen screen
    required property Item bar

    ExclusiveZone {
        anchors.left: true
        exclusiveZone: root.bar.exclusiveZone
    }

    ExclusiveZone {
        anchors.bottom: true
    }

    ExclusiveZone {
        anchors.right: true
    }

    ExclusiveZone {
        anchors.top: true
    }

    component ExclusiveZone: ArcWindow {
        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: Config.theme.hud.border.width
        mask: Region {}
    }
}
