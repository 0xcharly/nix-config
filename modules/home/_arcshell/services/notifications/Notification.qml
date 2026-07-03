pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import qs.services

QtObject {
    id: root

    property bool popup
    property bool closed
    property var locks: new Set()

    property date time: new Date()
    property string timeStr: qsTr("now")

    readonly property Timer timeStrTimer: Timer {
        running: !root.closed
        repeat: true
        interval: 5000
        onTriggered: root.updateTimeStr()
    }

    property Notification notification
    property string notificationId
    property string summary
    property string body
    property int urgency: NotificationUrgency.Normal

    readonly property Connections conn: Connections {
        function onClosed(): void {
            root.close();
        }

        function onSummaryChanged(): void {
            root.summary = root.notification.summary;
        }

        function onBodyChanged(): void {
            root.body = root.notification.body;
        }

        function onUrgencyChanged(): void {
            root.urgency = root.notification.urgency;
        }

        target: root.notification
    }

    function updateTimeStr(): void {
        const diff = Date.now() - time.getTime();
        const m = Math.floor(diff / 60000);

        if (m < 1) {
            timeStr = qsTr("now");
            timeStrTimer.interval = 5000;
        } else {
            const h = Math.floor(m / 60);
            const d = Math.floor(h / 24);

            if (d > 0) {
                timeStr = `${d}d`;
                timeStrTimer.interval = 3600000;
            } else if (h > 0) {
                timeStr = `${h}h`;
                timeStrTimer.interval = 300000;
            } else {
                timeStr = `${m}m`;
                timeStrTimer.interval = m < 10 ? 30000 : 60000;
            }
        }
    }

    function lock(item: Item): void {
        locks.add(item);
    }

    function unlock(item: Item): void {
        locks.delete(item);
        if (closed)
            close();
    }

    function close(): void {
        closed = true;
        if (locks.size === 0 && Notifications.list.includes(this)) {
            Notifications.list = Notifications.list.filter(n => n !== this);
            notification?.dismiss();
            destroy();
        }
    }

    Component.onCompleted: {
        if (!notification) {
            return;
        }

        notificationId = notification.id;
        summary = notification.summary;
        body = notification.body;
        urgency = notification.urgency;
    }
}
