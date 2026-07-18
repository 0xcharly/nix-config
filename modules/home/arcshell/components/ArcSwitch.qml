pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Templates
import qs.config
import qs.config.tokens.component as ComponentTokens

Switch {
    id: root

    property ComponentTokens.Switch theme: Config.theme.defaults.switches

    implicitWidth: implicitIndicatorWidth
    implicitHeight: implicitIndicatorHeight

    // Container
    indicator: ArcRectangle {
        radius: Config.tokens.system.shapes.cornerFull
        color: root.checked ? root.theme.trackColorChecked : root.theme.trackColorRest

        implicitWidth: implicitHeight * 1.7
        implicitHeight: root.theme.thumbSize + root.theme.thumbPadding.top + root.theme.thumbPadding.bottom

        // Thumb
        ArcRectangle {
            readonly property real nonAnimWidth: root.pressed ? implicitHeight * 1.3 : implicitHeight

            radius: Config.tokens.system.shapes.cornerFull
            color: root.checked ? root.theme.thumbColorChecked.surface : root.theme.thumbColorRest.surface

            x: root.checked ? parent.implicitWidth - nonAnimWidth - root.theme.thumbPadding.right : root.theme.thumbPadding.left
            implicitWidth: nonAnimWidth
            implicitHeight: root.theme.thumbSize
            anchors.verticalCenter: parent.verticalCenter

            // Thumb state overlay
            ArcRectangle {
                anchors.fill: parent

                radius: Config.tokens.system.shapes.cornerFull
                color: {
                    if (root.checked) {
                        if (root.pressed) {
                            return root.theme.thumbColorCheckedActive.surface;
                        } else if (root.hovered) {
                            return root.theme.thumbColorCheckedHover.surface;
                        }
                    } else {
                        // !root.checked
                        if (root.pressed) {
                            return root.theme.thumbColorActive.surface;
                        } else if (root.hovered) {
                            return root.theme.thumbColorHover.surface;
                        }
                    }

                    return "transparent";
                }
            }

            Shape {
                id: icon

                property point start1: {
                    if (root.pressed)
                        return Qt.point(width * 0.2, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.15, height / 2);
                    return Qt.point(width * 0.15, height * 0.15);
                }
                property point end1: {
                    if (root.pressed) {
                        if (root.checked)
                            return Qt.point(width * 0.4, height / 2);
                        return Qt.point(width * 0.8, height / 2);
                    }
                    if (root.checked)
                        return Qt.point(width * 0.4, height * 0.7);
                    return Qt.point(width * 0.85, height * 0.85);
                }
                property point start2: {
                    if (root.pressed) {
                        if (root.checked)
                            return Qt.point(width * 0.4, height / 2);
                        return Qt.point(width * 0.2, height / 2);
                    }
                    if (root.checked)
                        return Qt.point(width * 0.4, height * 0.7);
                    return Qt.point(width * 0.15, height * 0.85);
                }
                property point end2: {
                    if (root.pressed)
                        return Qt.point(width * 0.8, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.85, height * 0.2);
                    return Qt.point(width * 0.85, height * 0.15);
                }

                anchors.centerIn: parent
                width: height
                height: root.theme.thumbSize - root.theme.iconPadding.top - root.theme.iconPadding.bottom
                preferredRendererType: Shape.CurveRenderer
                asynchronous: true

                ShapePath {
                    strokeWidth: root.theme.iconStrokeWidth
                    strokeColor: root.checked ? root.theme.thumbColorChecked.content : root.theme.thumbColorRest.content
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    startX: icon.start1.x
                    startY: icon.start1.y

                    PathLine {
                        x: icon.end1.x
                        y: icon.end1.y
                    }
                    PathMove {
                        x: icon.start2.x
                        y: icon.start2.y
                    }
                    PathLine {
                        x: icon.end2.x
                        y: icon.end2.y
                    }

                    Behavior on strokeColor {
                        AnimatedColor {}
                    }
                }

                Behavior on start1 {
                    PropAnim {}
                }
                Behavior on end1 {
                    PropAnim {}
                }
                Behavior on start2 {
                    PropAnim {}
                }
                Behavior on end2 {
                    PropAnim {}
                }
            }

            Behavior on x {
                AnimatedNumber {}
            }

            Behavior on implicitWidth {
                AnimatedNumber {}
            }
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
