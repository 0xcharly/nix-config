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
    property bool hovered: mouseArea.containsMouse
    property bool pressed: false
    property ComponentTokens.QuickToggle theme: Config.theme.defaults.quickToggles

    signal leftClicked
    signal rightClicked

    radius: Config.tokens.system.shapes.cornerFull
    color: root.theme.surface.colors.surface

    implicitWidth: implicitHeight * 1.7
    implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom

    // Hover: a hoverLayer surface stacked on the card (the alphas
    // combine into a brighter tone), slightly inset per
    // hoverLayerPadding.
    Rectangle {
        anchors.fill: parent
        anchors.margins: root.theme.hoverLayerPadding
        radius: root.radius - root.theme.hoverLayerPadding
        color: root.theme.hoverLayer
        opacity: root.hovered ? 1 : 0

        Behavior on opacity {
            AnimatedNumber {
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
        }
    }

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

            AnimatedMaterialIcon {
                id: icon

                anchors.centerIn: parent

                icon: root.icon
                style: root.theme.icon.typography
                color: root.enabled ? root.theme.iconChecked.content : root.theme.icon.colors.content
                animation: root.theme.animation
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
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.leftClicked()
    }

    component PropAnim: PropertyAnimation {
        duration: root.theme.animation.duration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: root.theme.animation.curveIn
    }
}
