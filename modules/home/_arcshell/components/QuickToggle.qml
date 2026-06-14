pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.config.tokens.component as ComponentTokens

Rectangle {
    id: root

    property string icon
    property string text
    property bool enabled: false
    property bool hovered: false
    property bool pressed: false
    property ComponentTokens.QuickToggle theme: Config.theme.defaults.quickToggles

    radius: Config.tokens.system.shapes.cornerFull
    color: root.theme.surface.colors.surface

    implicitWidth: implicitHeight * 1.7
    implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: root.theme.padding.bottom
        anchors.leftMargin: root.theme.padding.left
        anchors.rightMargin: root.theme.padding.right
        anchors.topMargin: root.theme.padding.top
        spacing: root.theme.verticalSpacing

        // Icon
        ArcRectangle {
            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + root.theme.icon.padding.top + root.theme.padding.bottom

            radius: Config.tokens.system.shapes.cornerFull
            color: root.enabled ? root.theme.iconChecked.surface : root.theme.icon.colors.surface

            MaterialIcon {
                id: icon

                anchors.centerIn: parent

                text: root.icon
                style: root.theme.icon.typography
                color: root.enabled ? root.theme.iconChecked.content : root.theme.icon.colors.content
            }
        }

        ArcText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            text: root.text
            color: root.theme.surface.colors.content
            style: root.theme.typography
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: false
    }

    component PropAnim: PropertyAnimation {
        duration: root.theme.animation.duration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: root.theme.animation.curveIn
    }
}
