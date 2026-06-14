import QtQuick
import QtQuick.Templates
import qs.config
import qs.config.tokens.component as ComponentTokens

Slider {
    id: root

    required property string labelValue
    property ComponentTokens.Slider theme: Config.tokens.component.slider
    property real oldValue
    property bool initialized

    orientation: Qt.Vertical

    background: Rectangle {
        color: "transparent"

        implicitWidth: root.theme.width
        width: implicitWidth
        x: root.leftPadding + root.availableWidth / 2 - width / 2

        ArcRectangle {
            id: inactiveTrack

            anchors.left: parent.left
            anchors.right: parent.right

            implicitHeight: root.handle.y - root.theme.thumbSpacing - y

            color: root.theme.inactiveTrackColor
            topLeftRadius: root.theme.trackShapeOut
            topRightRadius: root.theme.trackShapeOut
            bottomLeftRadius: root.theme.trackShapeIn
            bottomRightRadius: root.theme.trackShapeIn
        }

        ArcRectangle {
            id: activeTrack

            anchors.left: parent.left
            anchors.right: parent.right

            y: root.handle.y + root.theme.thumbHeight + root.theme.thumbSpacing
            implicitHeight: parent.height - y

            color: root.theme.activeTrackColor
            topLeftRadius: root.theme.trackShapeIn
            topRightRadius: root.theme.trackShapeIn
            bottomLeftRadius: root.theme.trackShapeOut
            bottomRightRadius: root.theme.trackShapeOut
        }

        MaterialIcon {
            id: icon

            property bool moving

            function update(): void {
                binding.when = moving;
                style = moving ? root.theme.textTypography : root.theme.iconTypography;
            }

            style: root.theme.iconTypography
            text: root.labelValue
            color: root.value > 0.8 ? root.theme.activeTrackContentColor : root.theme.inactiveTrackContentColor
            anchors.top: root.value > 0.8 ? activeTrack.top : inactiveTrack.top
            anchors.topMargin: 4
            width: parent.width
            horizontalAlignment: Text.AlignHCenter

            onMovingChanged: {
                anim.restart();
            }

            Binding {
                id: binding

                target: icon
                property: "text"
                value: Math.round(root.value * 100)
                when: false
            }

            SequentialAnimation {
                id: anim

                AnimatedNumber {
                    target: icon
                    property: "scale"
                    to: 0
                    duration: root.theme.labelAnimation.duration
                    easing.bezierCurve: root.theme.labelAnimation.curveIn
                }
                ScriptAction {
                    script: icon.update()
                }
                AnimatedNumber {
                    target: icon
                    property: "scale"
                    to: 1
                    duration: root.theme.labelAnimation.duration
                    easing.bezierCurve: root.theme.labelAnimation.curveOut
                }
            }
        }
    }

    handle: Item {
        id: thumb

        property alias moving: icon.moving

        x: root.leftPadding + root.availableWidth / 2 - width / 2
        y: root.topPadding + root.visualPosition * (root.availableHeight - height)
        implicitWidth: root.theme.thumbWidth
        implicitHeight: root.theme.thumbHeight
        anchors.topMargin: root.theme.thumbSpacing
        anchors.bottomMargin: root.theme.thumbSpacing

        ArcRectangle {
            id: rect

            anchors.fill: parent

            color: root.theme.thumbColor
            radius: Config.tokens.system.shapes.cornerFull
        }
    }

    MouseArea {
        id: handleInteraction

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
    }

    onPressedChanged: thumb.moving = true

    onValueChanged: {
        if (!initialized) {
            initialized = true;
            return;
        }
        if (Math.abs(value - oldValue) < 0.01) {
            return;
        }
        oldValue = value;
        thumb.moving = true;
        stateChangeDelay.restart();
    }

    Timer {
        id: stateChangeDelay

        interval: root.theme.labelTypographyAnimationDelay
        onTriggered: {
            if (!root.pressed) {
                thumb.moving = false;
            }
        }
    }
}
