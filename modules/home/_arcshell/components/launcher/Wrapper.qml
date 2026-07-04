pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.config.tokens.component as ComponentTokens
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    readonly property bool shouldBeActive: UiState.showLauncher

    property ComponentTokens.Launcher theme: Config.tokens.component.launcher

    // 0 = collapsed, 1 = fully open. CRT power-on: the first `sweepSplit`
    // of the animation sweeps the horizontal border line out from the
    // center (widthProgress); the remainder parts the borders vertically
    // to reveal the content (heightProgress). One master value, so a
    // mid-animation reversal retraces the same visual path exactly.
    property real progress: 0

    // Clamped so neither phase degenerates if the token is misconfigured.
    readonly property real sweepSplit: Math.min(0.9, Math.max(0.1, theme.lineSweepFraction))
    readonly property real widthProgress: Math.min(1, progress / sweepSplit)
    // Clamped at 1: easing overshoot must not stretch the panel past its
    // natural size (a CRT does not bounce) — see the token comment.
    readonly property real heightProgress: Math.min(1, Math.max(0, (progress - sweepSplit) / (1 - sweepSplit)))

    // Touching GlyphSearch at startup materializes the singleton, so its
    // data files load, parse, and index before the launcher first opens
    // and takes keystrokes.
    Component.onCompleted: GlyphSearch.entries

    // Natural height of the loaded content; animated by Content itself,
    // so the panel and its border lines track candidate-list resizes.
    readonly property real contentHeight: loader.item?.implicitHeight ?? 0

    // Height of the content without a candidate list, for pinning the
    // panel's top border while the bottom one moves on list resizes.
    readonly property real restHeight: loader.item?.chromeHeight ?? 0

    // Vertical span between the horizontal borders: zero while the
    // phase-1 sweep runs (both borders overlap into a single line), the
    // revealed content height as phase 2 parts them.
    readonly property real borderSpan: contentHeight * heightProgress

    visible: progress > 0
    implicitWidth: theme.width * widthProgress
    // Floored at the border thickness so the wrapper never collapses to
    // a zero-size item while the phase-1 line sweep is on screen.
    implicitHeight: Math.max(theme.line.width, borderSpan)

    states: State {
        name: "visible"
        when: root.shouldBeActive

        PropertyChanges {
            root.progress: 1
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            AnimatedNumber {
                target: root
                property: "progress"
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
        },
        Transition {
            from: "visible"
            to: ""

            AnimatedNumber {
                target: root
                property: "progress"
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveOut
            }
        }
    ]

    // Content, revealed from the center as the wrapper grows.
    Item {
        anchors.fill: parent
        clip: true

        Loader {
            id: loader

            anchors.centerIn: parent

            Component.onCompleted: active = Qt.binding(() => root.shouldBeActive || root.visible)

            sourceComponent: Content {
                implicitWidth: root.theme.width
            }
        }
    }

    component Line: BorderLine {
        thickness: root.theme.line.width
        lineColor: root.theme.line.color
        fadeLength: root.theme.line.fade
        length: (horizontal ? root.widthProgress : root.heightProgress) * ((horizontal ? root.theme.width : root.contentHeight) + 2 * root.theme.line.overshoot)
    }

    Line {
        // Top
        horizontal: true
        x: (root.width - width) / 2
        y: (root.height - root.borderSpan) / 2 - root.theme.line.width / 2
    }
    Line {
        // Bottom
        horizontal: true
        x: (root.width - width) / 2
        y: (root.height + root.borderSpan) / 2 - root.theme.line.width / 2
    }
    Line {
        // Left
        horizontal: false
        x: -root.theme.line.width / 2
        y: (root.height - height) / 2
    }
    Line {
        // Right
        horizontal: false
        x: root.width - root.theme.line.width / 2
        y: (root.height - height) / 2
    }
}
