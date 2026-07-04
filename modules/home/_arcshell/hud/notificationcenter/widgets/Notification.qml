pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.config.tokens.component as ComponentTokens
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Tracked notification from Notifications.list: summary, body, close().
    // Repeater-injected.
    required property var modelData
    property ComponentTokens.Notification theme: Config.theme.defaults.notifications

    Layout.fillWidth: true
    implicitHeight: card.implicitHeight

    Rectangle {
        id: card

        width: root.width
        implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom

        color: root.theme.surface.colors.surface
        radius: root.theme.surface.shape
        // Fade out as the card is dragged toward dismissal.
        opacity: 1 - Math.abs(x) / width

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.bottomMargin: root.theme.padding.bottom
            anchors.leftMargin: root.theme.padding.left
            anchors.rightMargin: root.theme.padding.right
            anchors.topMargin: root.theme.padding.top
            spacing: root.theme.verticalSpacing

            ArcText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: root.theme.titleContentColor
                style: root.theme.titleTypography
                text: root.modelData.summary
            }

            ArcText {
                Layout.fillWidth: true
                visible: text !== ""
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                color: root.theme.surface.colors.content
                style: root.theme.surface.typography
                text: root.modelData.body
            }
        }

        MouseArea {
            id: dragArea

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            drag.target: card
            drag.axis: Drag.XAxis

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.modelData.close();
            }
            // Swipe: past a third of the card's width in either direction
            // dismisses; anything less springs back.
            onReleased: {
                if (Math.abs(card.x) > card.width / 3)
                    root.modelData.close();
                else
                    card.x = 0;
            }
        }

        Behavior on x {
            // Only animate the spring-back; never fight the active drag.
            enabled: !dragArea.drag.active

            AnimatedNumber {}
        }
    }
}
