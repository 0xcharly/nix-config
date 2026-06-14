pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string dayWeek: Qt.formatDate(clock.date, "ddd")
    readonly property string dayMonth: Qt.formatDate(clock.date, "dd")
    readonly property string time: Qt.formatTime(clock.date, "hh:mm")
    readonly property string timeHours: Qt.formatTime(clock.date, "hh")
    readonly property string timeMinutes: Qt.formatTime(clock.date, "mm")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
