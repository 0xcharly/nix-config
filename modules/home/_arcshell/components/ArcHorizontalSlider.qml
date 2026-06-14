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

    orientation: Qt.Horizontal

    background: Rectangle {
        color: "transparent"

        implicitHeight: root.theme.width
        height: implicitHeight
        y: root.topPadding + root.availableHeight / 2 - height / 2

        ArcRectangle {
            id: inactiveTrack

            anchors.top: parent.top
            anchors.bottom: parent.bottom

            x: root.handle.x + root.theme.thumbHeight + root.theme.thumbSpacing
            implicitWidth: parent.width - x

            color: root.theme.inactiveTrackColor
            topLeftRadius: root.theme.trackShapeIn
            topRightRadius: root.theme.trackShapeOut
            bottomLeftRadius: root.theme.trackShapeIn
            bottomRightRadius: root.theme.trackShapeOut
        }

        ArcRectangle {
            id: activeTrack

            anchors.top: parent.top
            anchors.bottom: parent.bottom

            implicitWidth: root.handle.x - root.theme.thumbSpacing - x

            color: root.theme.activeTrackColor
            topLeftRadius: root.theme.trackShapeOut
            topRightRadius: root.theme.trackShapeIn
            bottomLeftRadius: root.theme.trackShapeOut
            bottomRightRadius: root.theme.trackShapeIn
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
            anchors.right: root.value > 0.8 ? activeTrack.right : inactiveTrack.right
            anchors.rightMargin: 4
            height: parent.height
            verticalAlignment: Text.AlignVCenter

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

        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: root.theme.thumbHeight
        implicitHeight: root.theme.thumbWidth
        anchors.leftMargin: root.theme.thumbSpacing
        anchors.rightMargin: root.theme.thumbSpacing

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
