pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.config.tokens.component as ComponentTokens
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property string title
    required property string body
    property ComponentTokens.Notification theme: Config.theme.defaults.notifications

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom

    color: root.theme.surface.colors.surface
    radius: root.theme.surface.shape

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.bottomMargin: root.theme.padding.bottom
        anchors.leftMargin: root.theme.padding.left
        anchors.rightMargin: root.theme.padding.right
        anchors.topMargin: root.theme.padding.top
        spacing: root.theme.verticalSpacing

        ArcText {
            id: title

            horizontalAlignment: Text.AlignLeft

            tabularFigures: true
            color: root.theme.titleContentColor
            style: root.theme.titleTypography
            text: root.title
        }

        ArcText {
            id: body

            horizontalAlignment: Text.AlignLeft

            tabularFigures: true
            color: root.theme.surface.colors.content
            style: root.theme.surface.typography
            text: root.body
        }
    }
}
