pragma ComponentBehavior: Bound

import qs.config.tokens.feature
import qs.components
import qs.services as ArcServices
import QtQuick
import QtQuick.Layouts

ArcRectangle {
    id: root

    required property Clock theme

    implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom
    implicitWidth: layout.implicitWidth + root.theme.padding.left + root.theme.padding.right

    color: root.theme.colors.surface
    radius: root.theme.shape

    ColumnLayout {
        id: layout

        anchors.centerIn: parent

        Layout.alignment: Qt.AlignHCenter
        spacing: root.theme.spacing

        Layout.bottomMargin: root.theme.padding.bottom
        Layout.leftMargin: root.theme.padding.left
        Layout.rightMargin: root.theme.padding.right
        Layout.topMargin: root.theme.padding.top

        ArcRectangle {
            implicitHeight: time.implicitHeight + root.theme.timePadding.top + root.theme.timePadding.bottom
            implicitWidth: time.implicitWidth + root.theme.timePadding.left + root.theme.timePadding.right

            color: root.theme.timeColors.surface
            radius: root.theme.timeShape

            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: root.theme.timePadding.bottom
            Layout.leftMargin: root.theme.timePadding.left
            Layout.rightMargin: root.theme.timePadding.right
            Layout.topMargin: root.theme.timePadding.top

            ColumnLayout {
                id: time

                anchors.centerIn: parent

                ArcText {
                    Layout.alignment: Qt.AlignHCenter
                    tabularFigures: true
                    color: root.theme.colors.content
                    style: root.theme.typography
                    text: ArcServices.Clock.timeHours
                }
                ArcText {
                    Layout.alignment: Qt.AlignHCenter
                    tabularFigures: true
                    color: root.theme.colors.content
                    style: root.theme.typography
                    text: ArcServices.Clock.timeMinutes
                }
            }
        }

        ColumnLayout {
            id: date
            Layout.alignment: Qt.AlignHCenter

            ArcText {
                Layout.alignment: Qt.AlignHCenter
                tabularFigures: true
                color: root.theme.colors.content
                style: root.theme.typography
                text: ArcServices.Clock.dayMonth
            }
            ArcText {
                Layout.alignment: Qt.AlignHCenter
                color: root.theme.colors.content
                style: root.theme.typography
                text: ArcServices.Clock.dayWeek
            }
        }
    }
}
